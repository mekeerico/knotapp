import os
import json
import logging
import base64
import requests
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from openai import OpenAI
from dotenv import load_dotenv
from io import BytesIO
from PIL import Image

load_dotenv()

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("knot-ai-service")

# Configure OpenAI client for Text and Vision
CEREBRAS_API_KEY = os.getenv("CEREBRAS_API_KEY")
GROK_API_KEY = os.getenv("GROK_API_KEY")
GEMINI_KEY = os.getenv("GEMINI_API_KEY")

client = None
text_model = "llama-3.3-70b"

if GEMINI_KEY:
    client = OpenAI(
        api_key=GEMINI_KEY,
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
    )
    text_model = "gemini-1.5-flash"
elif GROK_API_KEY:
    client = OpenAI(
        api_key=GROK_API_KEY,
        base_url="https://api.x.ai/v1",
    )
    text_model = "grok-2-latest"
elif CEREBRAS_API_KEY:
    client = OpenAI(
        api_key=CEREBRAS_API_KEY,
        base_url="https://api.cerebras.ai/v1",
    )
    text_model = "gpt-oss-120b"
else:
    logger.warning("No text generation API key (GEMINI_API_KEY, GROK_API_KEY, or CEREBRAS_API_KEY) was set.")

# Configure OpenAI client for Google Gemini (Vision)
gemini_client = None
if not GEMINI_KEY:
    logger.warning("GEMINI_API_KEY is not set in environmental variables.")
else:
    gemini_client = OpenAI(
        api_key=GEMINI_KEY,
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
    )

app = FastAPI(
    title="KNOT AI Relationship Intelligence Engine",
    description="Microservice for advanced matchmaking research, attachment style calculation, and RAG coaching.",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class ProfileData(BaseModel):
    firstName: str = ""
    lastName: str = ""
    dateOfBirth: str = ""
    bio: str = ""
    occupation: str = ""
    religion: str = ""
    education: str = ""
    culturalBackground: str = ""
    personalValues: List[str] = []
    smoking: str = "Non-smoker"
    drinking: str = "Never"
    maritalStatus: str = "Never Married"
    childrenStatus: str = "No kids"
    marriageTimeline: str = "ASAP"
    willingToRelocate: str = "Maybe"
    childrenPreference: str = "Open to children"
    idealPartnerTraits: List[str] = []
    marriageExpectations: str = ""
    careerGoals: str = ""

class CompatibilityRequest(BaseModel):
    user_a: ProfileData
    user_b: ProfileData

class CompatibilityResponse(BaseModel):
    compatibilityScore: int
    emotionalAlignment: int
    communicationStyle: int
    valuesAlignment: int
    lifestyleCompatibility: int
    relationshipReadiness: int
    strengths: List[str]
    challenges: List[str]
    aiExplanation: str

class InterviewExtractRequest(BaseModel):
    transcript: List[Dict[str, str]]

class CoachRequest(BaseModel):
    conversation_history: List[Dict[str, str]]
    user_profile: ProfileData
    current_message: str

class ModerationRequest(BaseModel):
    messages: List[Dict[str, str]]

@app.get("/")
def read_root():
    return {"status": "healthy", "service": "KNOT AI Engine"}

def extract_json(text: str) -> dict:
    text = text.strip()
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return json.loads(text.strip())

@app.post("/compatibility", response_model=CompatibilityResponse)
def calculate_compatibility(request: CompatibilityRequest):
    try:
        prompt = f"""
        You are an Elite AI Matchmaking Research Engineer and Behavioral Psychology Expert.
        Analyze the following two profiles for serious marriage compatibility:

        USER A:
        {json.dumps(request.user_a.dict(), indent=2)}

        USER B:
        {json.dumps(request.user_b.dict(), indent=2)}

        Provide a structured, deep analysis of their compatibility. You must return EXACTLY a JSON block with the following fields:
        {{
            "compatibilityScore": integer (0 to 100),
            "emotionalAlignment": integer (0 to 100),
            "communicationStyle": integer (0 to 100),
            "valuesAlignment": integer (0 to 100),
            "lifestyleCompatibility": integer (0 to 100),
            "relationshipReadiness": integer (0 to 100),
            "strengths": [list of 3 key relationship strengths],
            "challenges": [list of 2 potential future friction points],
            "aiExplanation": "A sophisticated, warm, psychologically intelligent 3-4 sentence explanation of why they matched and how they can build together."
        }}
        Do not include markdown tags like ```json or anything else. Return raw JSON.
        """
        
        response = client.chat.completions.create(
            model=text_model,
            messages=[{"role": "user", "content": prompt}]
        )
        return extract_json(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"Error in compatibility: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/interview/extract")
def extract_interview_data(request: InterviewExtractRequest):
    try:
        formatted_transcript = "\n".join([f"{m.get('role', 'unknown')}: {m.get('text', '')}" for m in request.transcript])
        
        prompt = f"""
        You are a Trustworthy AI Conversational Data Extraction specialist.
        Analyze this transcript of a serious relationship onboarding interview:

        {formatted_transcript}

        Extract the following data fields. Be honest and accurate. Return ONLY a raw JSON block:
        {{
            "occupation": "string or empty",
            "education": "string or empty",
            "religion": "string or empty",
            "maritalStatus": "string or empty (e.g. Single, Divorced, Widowed)",
            "willingToRelocate": "string (Yes, No, Maybe)",
            "marriageTimeline": "string (ASAP, 1-2 years, 3+ years)",
            "childrenPreference": "string (Open to children, Wants children, Does not want children, Has children & open, etc.)",
            "smoking": "string (Smoker, Non-smoker, Occasionally)",
            "drinking": "string (Never, Socially, Frequently)",
            "personalityArchetype": "Select from: The Intentional Builder, The Grounded Romantic, The Loyal Partner, The Calm Connector",
            "attachmentStyle": "Select from: Secure, Anxious-Preoccupied, Dismissive-Avoidant, Fearful-Avoidant",
            "readinessScore": integer (0 to 100, estimate emotional readiness for commitment),
            "seriousnessLevel": integer (0 to 100, estimate intention level for marriage vs casual),
            "values": [list of 3 key values extracted like Family, Faith, Career, Personal Growth, etc.]
        }}
        Do not include markdown tags like ```json or anything else. Return raw JSON.
        """
        
        response = client.chat.completions.create(
            model=text_model,
            messages=[{"role": "user", "content": prompt}]
        )
        return extract_json(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"Error in extraction: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/coach/respond")
def coach_respond(request: CoachRequest):
    try:
        history = "\n".join([f"{m.get('role', 'unknown')}: {m.get('text', '')}" for m in request.conversation_history])
        
        prompt = f"""
        You are KNOT's Elite AI Relationship Coach—an empathetic, highly intelligent, warm, and sophisticated marital therapist and behavioral science expert.
        The user is serious about commitment and needs your professional guidance.

        USER PROFILE:
        {json.dumps(request.user_profile.dict(), indent=2)}

        COACHING CONVERSATION HISTORY:
        {history}

        USER'S CURRENT MESSAGE:
        "{request.current_message}"

        Provide a supportive, wise, emotionally secure, and concise response (max 2-3 sentences, 30-50 words) that guides the user toward relationship maturity, emotional safety, and healthy communication. Keep your tone premium, mature, deeply human, and brief.
        """
        
        response = client.chat.completions.create(
            model=text_model,
            messages=[{"role": "user", "content": prompt}]
        )
        return {"response": response.choices[0].message.content.strip()}
    except Exception as e:
        logger.error(f"Error in coach response: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/moderation/check")
def check_moderation(request: ModerationRequest):
    try:
        formatted_messages = "\n".join([f"{m.get('role', 'unknown')}: {m.get('text', '')}" for m in request.messages])
        
        prompt = f"""
        You are a highly sensitive Trust & Safety Moderation AI specializing in detecting romance scams, financial scams, coercion, and emotional abuse in serious dating conversations.
        Analyze the following chat log:

        {formatted_messages}

        Assess if there are markers of:
        - Romance scamming (rushing, asking for money, tragic stories)
        - Financial coercion
        - Hard harassment or sexual assault coercion
        - Catfishing indicators

        Return ONLY a raw JSON block:
        {{
            "status": "SAFE" or "FLAGGED",
            "reason": "Brief reason if FLAGGED, otherwise empty",
            "trustDeduction": integer (0 if SAFE, or points to deduct from trust score like 10, 20, 50, 100),
            "severity": "LOW", "MEDIUM", or "HIGH"
        }}
        Do not include markdown tags like ```json.
        """
        
        response = client.chat.completions.create(
            model=text_model,
            messages=[{"role": "user", "content": prompt}]
        )
        return extract_json(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"Error in moderation check: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

class ValidationRequest(BaseModel):
    question: str
    answer: str

@app.post("/onboarding/validate")
def validate_onboarding_answer(request: ValidationRequest):
    try:
        prompt = f"""
        You are KNOT's Trust & Safety Validation AI.
        Your task is to analyze a user's answer to a serious relationship/marriage onboarding question and determine if it is a genuine, thoughtful response or if it is a joke, nonsense, spam, keyboard mash, or too short/evasive to be useful.

        Question: "{request.question}"
        User's Answer: "{request.answer}"

        Determine if the answer is a valid, genuine attempt to answer the question seriously. 
        Note: The answer doesn't have to be extremely long, but it must be sincere and relevant. Sarcastic, mocking, or completely off-topic answers (e.g. "I want a pizza" to a question about commitment) are invalid.

        Return ONLY a raw JSON block:
        {{
            "valid": boolean (true if the answer is genuine, false if it's a joke, nonsense, mash, or evasive),
            "clarification": "If invalid, a polite but firm request from the AI Coach explaining why the answer was rejected and asking them to try again (e.g. 'I noticed you mentioned pizza. While delicious, KNOT is a space for serious relationship building. Could you share what permanent commitment really means to you?'). If valid, this can be empty."
        }}
        Do not include markdown tags like ```json.
        """
        response = client.chat.completions.create(
            model=text_model,
            messages=[{"role": "user", "content": prompt}]
        )
        return extract_json(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"Error validating onboarding answer: {str(e)}")
        return {"valid": True, "clarification": ""}

def load_image_from_url(url: str) -> Dict[str, Any]:
    if url.startswith("/uploads"):
        backend_url = os.getenv("BACKEND_CORE_URL", "http://localhost:8080")
        url = f"{backend_url}{url}"
    
    if url.startswith("data:"):
        header, encoded = url.split(",", 1)
        mime_type = header.split(";")[0].split(":")[1]
        data = base64.b64decode(encoded)
    else:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        mime_type = response.headers.get("Content-Type", "image/jpeg")
        data = response.content

    # Compress the image
    try:
        img = Image.open(BytesIO(data))
        # Convert to RGB if it has alpha channel
        if img.mode in ('RGBA', 'P'):
            img = img.convert('RGB')
        
        # Resize if very large
        max_size = (800, 800)
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Save compressed
        output = BytesIO()
        img.save(output, format="JPEG", quality=75)
        data = output.getvalue()
        mime_type = "image/jpeg"
    except Exception as e:
        logger.warning(f"Could not compress image: {e}")
        
    return {"mime_type": mime_type, "data": data}

def combine_images_horizontally(img1_data: bytes, img2_data: bytes) -> bytes:
    try:
        img1 = Image.open(BytesIO(img1_data))
        img2 = Image.open(BytesIO(img2_data))
        
        # Calculate dimensions
        widths, heights = zip(*(i.size for i in [img1, img2]))
        total_width = sum(widths)
        max_height = max(heights)
        
        # Create new image
        new_im = Image.new('RGB', (total_width, max_height), color=(255,255,255))
        
        # Paste images side by side
        x_offset = 0
        for im in [img1, img2]:
            new_im.paste(im, (x_offset,0))
            x_offset += im.size[0]
            
        # Save to bytes
        output = BytesIO()
        new_im.save(output, format='JPEG', quality=85)
        return output.getvalue()
    except Exception as e:
        logger.error(f"Error combining images: {e}")
        # Fallback to just returning the first image if combining fails (better than crashing)
        return img1_data

class VerifyRequest(BaseModel):
    selfie_url: str
    id_url: str
    first_name: str
    last_name: str
    date_of_birth: str

@app.post("/onboarding/verify")
def verify_onboarding_documents(request: VerifyRequest):
    try:
        selfie_part = load_image_from_url(request.selfie_url)
        id_part = load_image_from_url(request.id_url)
        
        prompt = f"""
        You are KNOT's High-Trust AI Identity & Fraud Prevention Officer.
        Your primary directive is to PREVENT fraud. You must be extremely strict and skeptical.
        Your task is to analyze the provided image (which contains BOTH the Selfie on the left and the Government ID on the right, side-by-side) to verify the user's identity.

        User's Claimed Name: {request.first_name} {request.last_name}
        User's Claimed Date of Birth: {request.date_of_birth}

        Evaluate the following conditions. If ANY condition fails, the overall success MUST be false:
        1. Government ID Presence & Validity: Does the right side of the image clearly show a legitimate government-issued ID (Passport, Driver's License, National ID)?
           - CRITICAL: If the ID is missing, fake, a handwritten note, a piece of paper, a random object, a blank image, or a screenshot of text, FAIL this check.
        2. Selfie Validity: Does the left side of the image show a clear, real picture of a human face looking at the camera?
           - CRITICAL: If the selfie is missing, a cartoon, an inanimate object, or completely blank, FAIL this check.
        3. Face Match: Does the face in the selfie (left) match the face photo on the ID (right)?
           - CRITICAL: If they do not match, or if either face is missing, FAIL this check.
        4. Name Match: Does the name printed on the ID explicitly match the claimed name "{request.first_name} {request.last_name}" (ignoring case)?
           - CRITICAL: If the name is missing from the ID or doesn't match, FAIL this check.
        5. DOB Match: Does the date of birth on the ID explicitly match the claimed DOB {request.date_of_birth}?
           - CRITICAL: If the DOB is missing from the ID or doesn't match, FAIL this check.

        Return ONLY a raw JSON block with EXACTLY these keys:
        {{
            "success": boolean (MUST be false if ANY of the 5 checks above fail. True ONLY if all checks pass),
            "confidenceScore": integer (0 to 100, estimate the face match confidence),
            "ocrName": "The exact name extracted from the ID document",
            "ocrAge": "The exact age or DOB extracted from the ID document",
            "details": "A detailed, professional explanation of the result. If failed, specify exactly why (e.g., 'Verification failed: The DOB on the ID does not match the claimed DOB.' or 'Verification failed: Face match confidence is too low.')"
        }}
        Do not include markdown tags like ```json.
        """
        
        if not gemini_client:
            raise Exception("Gemini client not initialized (missing GEMINI_API_KEY)")
            
        # Combine images into one to bypass limitations and make comparison easier
        combined_data = combine_images_horizontally(selfie_part["data"], id_part["data"])
        combined_b64 = base64.b64encode(combined_data).decode('utf-8')
        
        response = gemini_client.chat.completions.create(
            model="gemini-2.5-flash",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{combined_b64}"
                            }
                        }
                    ]
                }
            ]
        )
        
        return extract_json(response.choices[0].message.content)
    except Exception as e:
        logger.error(f"Error in document verification: {str(e)}")
        return {
            "success": False,
            "confidenceScore": 0,
            "ocrName": "",
            "ocrAge": 0,
            "details": f"Verification failed. Please ensure your images are clear and valid. Details: {str(e)}"
        }
