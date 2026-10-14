import { Controller, Post, Body } from '@nestjs/common';
import { AIService } from './ai.service';

@Controller('ai')
export class AIController {
  constructor(private readonly aiService: AIService) {}

  @Post('coach')
  async coachResponse(@Body() body: any) {
    const conversationHistory =
      body?.conversationHistory || body?.conversation_history || [];
    const userProfile = body?.userProfile || body?.user_profile || {};
    const currentMessage =
      body?.currentMessage || body?.current_message || body?.message || "";
    const response = await this.aiService.getCoachResponse(
      conversationHistory,
      userProfile,
      currentMessage
    );
    return { response };
  }

  @Post('compatibility')
  async compatibility(
    @Body() body: {
      user_a: any;
      user_b: any;
    }
  ) {
    const { user_a, user_b } = body;
    return this.aiService.calculateCompatibility(user_a, user_b);
  }
}
