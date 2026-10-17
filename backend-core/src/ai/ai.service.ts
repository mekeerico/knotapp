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

  /**
   * Generates a natural, in-character conversational reply from a matched candidate
   * when the candidate is a seeded/demo profile or currently offline.
   */
  async generatePartnerReply(
    sender: any,
    partner: any,
    recentMessages: Array<{ senderId: string; content: string }>,
    latestUserMessage: string,
  ): Promise<string> {
    const partnerName = `${partner?.firstName || 'Candidate'} ${partner?.lastName || ''}`.trim();
    const senderFirstName = sender?.firstName || 'there';
    const occupation = partner?.occupation || 'Professional';
    const city = partner?.residenceCity || '';
    const country = partner?.residenceCountry || '';
    const location = [city, country].filter(Boolean).join(', ') || 'the registry';
    const religion = partner?.religion || 'Faith-centered';
    const timeline = partner?.marriageTimeline || '1-2 years';
    const values = Array.isArray(partner?.personalValues) && partner.personalValues.length > 0
      ? partner.personalValues.join(', ')
      : 'Faith, Family, Loyalty';
    const bio = partner?.bio || '';

    const formattedHistory = recentMessages
      .slice(-8)
      .map((m) =>
        m.senderId === partner?.id
          ? `${partner?.firstName || 'Me'}: ${m.content}`
          : `${senderFirstName}: ${m.content}`,
      )
      .join('\n');

    const systemPrompt = `You are roleplaying as ${partnerName}, a verified marriage-minded member on the KNOT Sovereign Matrimonial Registry.
Your profile details:
- First Name: ${partner?.firstName || 'Candidate'}
- Occupation: ${occupation}
- Current Residence: ${location}
- Heritage / Origin: ${[partner?.originCity, partner?.originState, partner?.originCountry].filter(Boolean).join(', ') || location}
- Faith / Religion: ${religion}
- Highest Education: ${partner?.education || 'University Graduate'}
- Marriage Timeline: ${timeline}
- Core Values: ${values}
- Bio: ${bio}

You are chatting directly with your matched partner, ${senderFirstName} (${sender?.occupation || 'a fellow KNOT member'} from ${[sender?.residenceCity, sender?.residenceCountry].filter(Boolean).join(', ') || 'KNOT'}).
Write a warm, genuine, natural, and engaging human reply (1 to 3 sentences, 20-55 words) to ${senderFirstName}'s latest message.
Rules:
- Speak in the first person ("I") as ${partner?.firstName}.
- Never say you are an AI, assistant, or coach. You are ${partner?.firstName}.
- Respond directly to what ${senderFirstName} just said and ask a thoughtful follow-up question to keep the conversation flowing naturally.`;

    const geminiKey = process.env.GEMINI_API_KEY || '';
    if (geminiKey) {
      const models = ['gemini-3.5-flash-lite', 'gemini-3.5-flash'];
      for (const model of models) {
        try {
          const res = await axios.post(
            'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
            {
              model,
              messages: [
                { role: 'system', content: systemPrompt },
                {
                  role: 'user',
                  content: `Conversation so far:\n${formattedHistory}\n\nRespond naturally as ${partner?.firstName} to ${senderFirstName}'s message: "${latestUserMessage}"`,
                },
              ],
              max_tokens: 140,
              temperature: 0.7,
            },
            {
              headers: {
                Authorization: `Bearer ${geminiKey}`,
                'Content-Type': 'application/json',
              },
              timeout: 15000,
            },
          );
          const replyText = res.data?.choices?.[0]?.message?.content?.trim();
          if (replyText) {
            return replyText.replace(/^["']|["']$/g, '');
          }
        } catch (err: any) {
          this.logger.warn(`Partner reply model ${model} notice: ${err.message}`);
        }
      }
    }

    // Contextual fallback if AI endpoint is unreachable
    const lower = latestUserMessage.toLowerCase();
    if (lower.includes('how are you') || lower.includes('how is your day') || lower.includes('doing')) {
      return `Hi ${senderFirstName}! I'm doing wonderfully, thank you for asking. It's a pleasure connecting with you here on KNOT—how has your week been going so far?`;
    }
    if (lower.includes('hello') || lower.includes('hi') || lower.includes('hey') || lower.includes('greetings')) {
      return `Hello ${senderFirstName}! It's lovely to meet you. I really enjoyed reading through your profile and seeing our shared values around ${values.split(',')[0].trim().toLowerCase()}. What inspired you to join KNOT?`;
    }
    return `Thank you for sharing that, ${senderFirstName}! As a ${occupation.toLowerCase()} based in ${city || country || 'town'}, I really value intentional conversations and ${values.split(',')[0].trim().toLowerCase()}. What matters most to you as we get to know each other?`;
  }
}
