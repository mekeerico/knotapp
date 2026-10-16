import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class AIService {
  private readonly logger = new Logger(AIService.name);
  private get aiServiceUrl(): string {
    const url = process.env.AI_SERVICE_URL || 'http://localhost:5000';
    return url.startsWith('http') ? url : `http://${url}`;
  }

  async calculateCompatibility(userA: any, userB: any): Promise<any> {
    try {
      const response = await axios.post(`${this.aiServiceUrl}/compatibility`, {
        user_a: userA,
        user_b: userB,
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Error calculating compatibility: ${error.message}`);
      return {
        compatibilityScore: 50,
        emotionalAlignment: 50,
        communicationStyle: 50,
        valuesAlignment: 50,
        lifestyleCompatibility: 50,
        relationshipReadiness: 50,
        strengths: ['Shared background'],
        challenges: ['Potential value differences'],
        aiExplanation: 'An error occurred calculating deeper insights, but a baseline match is possible.',
      };
    }
  }

  async extractInterviewData(transcript: Array<{ role: string; text: string }>): Promise<any> {
    try {
      const response = await axios.post(`${this.aiServiceUrl}/interview/extract`, {
        transcript,
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Error extracting interview data: ${error.message}`);
      return null;
    }
  }

  async getCoachResponse(
    conversationHistory: Array<{ role: string; text: string }>,
    userProfile: any,
    currentMessage: string,
  ): Promise<string> {
    try {
      const response = await axios.post(
        `${this.aiServiceUrl}/coach/respond`,
        {
          conversation_history: conversationHistory,
          user_profile: userProfile,
          current_message: currentMessage,
        },
        { timeout: 15000 },
      );
      return response.data.response;
    } catch (error) {
      this.logger.error(`Error from AI coach: ${error.message}`);
      return "I'm having a little trouble connecting with my insights right now. Let's talk about what makes you feel emotionally safe in a relationship.";
    }
  }

  async checkModeration(messages: Array<{ role: string; text: string }>): Promise<any> {
    try {
      const response = await axios.post(`${this.aiServiceUrl}/moderation/check`, {
        messages,
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Error in moderation check: ${error.message}`);
      return { status: 'SAFE', reason: '', trustDeduction: 0, severity: 'LOW' };
    }
  }

  async validateOnboardingAnswer(question: string, answer: string): Promise<any> {
    try {
      const response = await axios.post(`${this.aiServiceUrl}/onboarding/validate`, {
        question,
        answer,
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Error in onboarding validation: ${error.message}`);
      return { valid: true, clarification: '' };
    }
  }

  async verifyOnboardingDocuments(selfieUrl: string, idUrl: string, firstName: string, lastName: string, dateOfBirth: string): Promise<any> {
    try {
      const response = await axios.post(`${this.aiServiceUrl}/onboarding/verify`, {
        selfie_url: selfieUrl,
        id_url: idUrl,
        first_name: firstName,
        last_name: lastName,
        date_of_birth: dateOfBirth,
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Error in onboarding verification: ${error.message}`);
      return {
        success: false,
        confidenceScore: 0,
        ocrName: '',
        ocrAge: '',
        details: `Verification failed due to backend processing error: ${error.message}`,
      };
    }
  }
}
