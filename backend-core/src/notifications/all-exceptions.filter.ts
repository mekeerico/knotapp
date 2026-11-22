import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { DeveloperAlertService } from './developer-alert.service';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  constructor(private readonly devAlertService: DeveloperAlertService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request & { user?: { userId?: string; id?: string } }>();

    const isHttp = exception instanceof HttpException;
    const status = isHttp
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse = isHttp ? exception.getResponse() : null;
    const errorMessage =
      typeof exceptionResponse === 'string'
        ? exceptionResponse
        : (exceptionResponse as any)?.message ||
          (exception as any)?.message ||
          'Internal server error';

    if (status >= 500) {
      this.logger.error(
        `[${status}] ${request?.method} ${request?.originalUrl}: ${errorMessage}`,
        (exception as any)?.stack,
      );

      // Fire-and-forget developer alert so the HTTP response is never delayed
      this.devAlertService
        .notifyHttpError({
          method: request?.method || 'UNKNOWN',
          url: request?.originalUrl || request?.url || 'UNKNOWN',
          statusCode: status,
          errorMessage: Array.isArray(errorMessage)
            ? errorMessage.join(', ')
            : String(errorMessage),
          stack: (exception as any)?.stack,
          userId: request?.user?.userId || request?.user?.id,
        })
        .catch(() => {});
    }

    if (isHttp && typeof exceptionResponse === 'object' && exceptionResponse !== null) {
      response.status(status).json(exceptionResponse);
      return;
    }

    response.status(status).json({
      statusCode: status,
      message: errorMessage,
      timestamp: new Date().toISOString(),
      path: request?.url,
    });
  }
}
