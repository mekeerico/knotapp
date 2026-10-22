import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { PrismaService } from './prisma/prisma.service';
import * as express from 'express';
import { join } from 'path';
import * as fs from 'fs';

async function bootstrap() {
  const uploadsDir = join(process.cwd(), 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  const app = await NestFactory.create(AppModule);
  app.enableCors();

  const prisma = app.get(PrismaService);
  const httpAdapter = app.getHttpAdapter().getInstance();

  // Automatic database purge on server deployment to eliminate all seeded/mock demo profiles
  try {
    const deleted = await prisma.user.deleteMany({
      where: {
        AND: [
          // Never delete the real user account (e.g. Emeke)
          {
            NOT: [
              { email: { contains: 'emeke', mode: 'insensitive' } },
              { firstName: { contains: 'Emeke', mode: 'insensitive' } },
            ],
          },
          {
            OR: [
              { passwordHash: 'mock' },
              { passwordHash: { not: { startsWith: '$2' } } },
              { id: { startsWith: 'match_' } },
              { id: { startsWith: 'mock_' } },
              { id: { startsWith: 'user_' } },
              { email: { contains: 'mock', mode: 'insensitive' } },
              { email: { contains: 'test', mode: 'insensitive' } },
              { firstName: 'Amara', lastName: 'Okonkwo' },
              { firstName: 'Dr. Amara' },
            ],
          },
        ],
      },
    });
    if (deleted.count > 0) {
      console.log(`[DATABASE PURGE] Successfully purged ${deleted.count} legacy mock/demo users from production database.`);
    }
  } catch (err: any) {
    console.warn(`[DATABASE PURGE NOTICE] ${err.message}`);
  }

  // Fast binary image endpoint for database-stored profile photos
  httpAdapter.get('/uploads/db-image/:id', async (req: express.Request, res: express.Response) => {
    try {
      const id = String(req.params.id || '').replace(/[^a-zA-Z0-9_-]/g, '');
      if (!id) return res.status(404).end();

      const cacheFile = join(uploadsDir, `cache_img_${id}.jpg`);
      if (fs.existsSync(cacheFile)) {
        res.setHeader('Content-Type', 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        return res.sendFile(cacheFile);
      }

      const img = await prisma.image.findUnique({ where: { id } });
      if (!img || !img.url) return res.status(404).end();

      if (img.url.startsWith('http://') || img.url.startsWith('https://')) {
        return res.redirect(img.url);
      }

      const base64Data = img.url.includes('base64,') ? img.url.split('base64,')[1] : img.url;
      const buffer = Buffer.from(base64Data, 'base64');
      try {
        fs.writeFileSync(cacheFile, buffer);
      } catch (_) {}

      res.setHeader('Content-Type', 'image/jpeg');
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      return res.send(buffer);
    } catch (_) {
      return res.status(404).end();
    }
  });

  // Fast binary image endpoint for database-stored user selfies
  httpAdapter.get('/uploads/db-selfie/:id', async (req: express.Request, res: express.Response) => {
    try {
      const id = String(req.params.id || '').replace(/[^a-zA-Z0-9_-]/g, '');
      if (!id) return res.status(404).end();

      const cacheFile = join(uploadsDir, `cache_selfie_${id}.jpg`);
      if (fs.existsSync(cacheFile)) {
        res.setHeader('Content-Type', 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return res.sendFile(cacheFile);
      }

      const user = await prisma.user.findUnique({
        where: { id },
        select: { selfieUrl: true },
      });
      if (!user || !user.selfieUrl) return res.status(404).end();

      if (user.selfieUrl.startsWith('http://') || user.selfieUrl.startsWith('https://')) {
        return res.redirect(user.selfieUrl);
      }

      const base64Data = user.selfieUrl.includes('base64,')
        ? user.selfieUrl.split('base64,')[1]
        : user.selfieUrl;
      const buffer = Buffer.from(base64Data, 'base64');
      try {
        fs.writeFileSync(cacheFile, buffer);
      } catch (_) {}

      res.setHeader('Content-Type', 'image/jpeg');
      res.setHeader('Cache-Control', 'public, max-age=86400');
      return res.send(buffer);
    } catch (_) {
      return res.status(404).end();
    }
  });

  // Serve static uploads
  app.use('/uploads', express.static(uploadsDir, { maxAge: '7d' }));
  // Allow larger payload sizes for image base64 or multipart uploads
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));
  await app.listen(process.env.PORT ?? 8080);
}
bootstrap();
