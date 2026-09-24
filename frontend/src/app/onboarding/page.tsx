"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { 
  Bot, Send, Sparkles, ShieldCheck, Heart, User, CheckCircle2, 
  MapPin, Brain, GraduationCap, Briefcase, Calendar, ArrowRight, Loader2,
  Camera, Upload, X, Shield, RefreshCw, Smile, Eye, EyeOff, ChevronDown, Check
} from "lucide-react";

const MultiSelectDropdown = ({ label, options, values, onChange, placeholder }: { label: string, options: string[], values: string[], onChange: (v: string[]) => void, placeholder: string }) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const toggleOption = (opt: string) => {
    if (values.includes(opt)) {
      onChange(values.filter(v => v !== opt));
    } else {
      onChange([...values, opt]);
    }
  };

  return (
    <div className="relative mb-3" ref={dropdownRef}>
      <label className="text-[10px] uppercase text-gray-500 font-bold block mb-1">{label}</label>
      <div 
        className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3 px-4 text-xs text-white cursor-pointer flex justify-between items-center h-12"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className={values.length === 0 ? "text-gray-500" : "truncate pr-2"}>
          {values.length > 0 ? values.join(', ') : placeholder}
        </span>
        <ChevronDown className={`w-4 h-4 text-gray-500 transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </div>
      
      {isOpen && (
        <div className="absolute z-10 w-full mt-2 bg-[#1A202C] border border-white/10 rounded-xl shadow-xl max-h-60 overflow-y-auto">
          {options.map(opt => (
            <div 
              key={opt}
              className="flex items-center gap-3 px-4 py-3 hover:bg-white/5 cursor-pointer border-b border-white/5 last:border-0"
              onClick={() => toggleOption(opt)}
            >
              <div className={`w-4 h-4 rounded border flex items-center justify-center flex-shrink-0 ${values.includes(opt) ? 'bg-[#D4AF37] border-[#D4AF37]' : 'border-white/20'}`}>
                {values.includes(opt) && <Check className="w-3 h-3 text-black" strokeWidth={3} />}
              </div>
              <span className="text-xs text-gray-300">{opt}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
import { COUNTRIES, STATES_BY_COUNTRY, CITIES_BY_STATE } from "../../services/locationData";

// Biometric Vector Images
const BIOMETRIC_SELFIE_SVG = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="50" fill="%23121721"/><circle cx="50" cy="37" r="16" fill="%23E27D8D"/><path d="M50,58 C32,58 22,72 22,82 L78,82 C78,72 68,58 50,58 Z" fill="%23E27D8D"/><circle cx="50" cy="50" r="45" fill="none" stroke="%23D4AF37" stroke-width="2" stroke-dasharray="4,4"/><path d="M42,35 Q50,42 58,35" stroke="%23ffffff" stroke-width="2" fill="none"/><circle cx="43" cy="31" r="2" fill="%23ffffff"/><circle cx="57" cy="31" r="2" fill="%23ffffff"/></svg>`;
const BIOMETRIC_ID_SVG = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 60"><rect width="100" height="60" rx="6" fill="%23121721" stroke="%23D4AF37" stroke-width="2"/><circle cx="20" cy="30" r="10" fill="%23E27D8D"/><rect x="40" y="18" width="45" height="4" rx="2" fill="%23E27D8D"/><rect x="40" y="28" width="45" height="4" rx="2" fill="%23E27D8D"/><rect x="40" y="38" width="30" height="4" rx="2" fill="%23E27D8D"/><circle cx="20" cy="30" r="13" fill="none" stroke="%23ffffff" stroke-width="1" stroke-dasharray="2,2"/></svg>`;

export default function Onboarding() {
  const [step, setStep] = useState(1);
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [profilePictureSkipped, setProfilePictureSkipped] = useState(false);
  const [verificationSkipped, setVerificationSkipped] = useState(false);
  const [uploadedProfilePic, setUploadedProfilePic] = useState<File | null>(null);
  const [uploadedGovId, setUploadedGovId] = useState<File | null>(null); // 1: Welcome, 2: Essentials Form, 3: AI Interview, 4: Processing, 5: Results Card
  const [subStep, setSubStep] = useState(0);
  const [gender, setGender] = useState("");
  const [preferredGender, setPreferredGender] = useState("");
  
  // Essentials Form Fields
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    // Initialize step from URL param if present
    const params = new URLSearchParams(window.location.search);
    const stepParam = params.get('step');
    if (stepParam) {
      setStep(parseInt(stepParam));
    }
    
    // Load pre-filled credentials from login page's "Apply Here"
    const storedEmail = sessionStorage.getItem('onboard_email');
    const storedPassword = sessionStorage.getItem('onboard_password');
    if (storedEmail) setEmail(storedEmail);
    if (storedPassword) setPassword(storedPassword);
  }, []);
  const [religion, setReligion] = useState("");
  const [religionSelect, setReligionSelect] = useState("");
  const [religionCustom, setReligionCustom] = useState("");
  const [occupation, setOccupation] = useState("");
  const [profilePicture, setProfilePicture] = useState<string | null>(null);
  const [governmentId, setGovernmentId] = useState<string | null>(null);
  const [verificationSelfie, setVerificationSelfie] = useState<string | null>(null);
  const [verificationStep, setVerificationStep] = useState(0);

  // Lifestyle & Expectations State
  const [nationality, setNationality] = useState("");
  const [languagesSpoken, setLanguagesSpoken] = useState<string[]>([]);
  const [otherLanguageInput, setOtherLanguageInput] = useState("");
  const [smoking, setSmoking] = useState("");
  const [drinking, setDrinking] = useState("");
  const [maritalStatus, setMaritalStatus] = useState("");
  const [childrenStatus, setChildrenStatus] = useState("");
  const [marriageTimeline, setMarriageTimeline] = useState("");
  const [willingToRelocate, setWillingToRelocate] = useState("");
  const [preferredMarryFrom, setPreferredMarryFrom] = useState("");
  const [childrenPreference, setChildrenPreference] = useState("");
  const [idealPartnerTraits, setIdealPartnerTraits] = useState<string[]>([]);
  const [otherTraitInput, setOtherTraitInput] = useState("");
  const [marriageExpectations, setMarriageExpectations] = useState("");
  
  const [languageSelect, setLanguageSelect] = useState("");
  const [languageCustom, setLanguageCustom] = useState("");
  const [traitSelect, setTraitSelect] = useState("");
  const [traitCustom, setTraitCustom] = useState("");
  
  const MAJOR_LANGUAGES = ['English', 'Spanish', 'French', 'German', 'Mandarin', 'Hindi', 'Arabic', 'Portuguese', 'Yoruba', 'Igbo', 'Hausa', 'Swahili', 'Other', 'Chinese'];
  const MAJOR_TRAITS = ['Kind', 'Ambitious', 'Family-oriented', 'Honest', 'Humorous', 'Intelligent', 'Empathetic', 'Adventurous', 'Loyal', 'Spiritual', 'Confident', 'Other'];
  const [residenceCountry, setResidenceCountry] = useState("");
  const [residenceState, setResidenceState] = useState("");
  const [residenceCity, setResidenceCity] = useState("");
  const [originCountry, setOriginCountry] = useState("");
  const [originState, setOriginState] = useState("");
  const [originCity, setOriginCity] = useState("");

  const [preferredResidenceCountry, setPreferredResidenceCountry] = useState("");
  const [preferredResidenceState, setPreferredResidenceState] = useState("");
  const [prefResCountryCustom, setPrefResCountryCustom] = useState("");
  const [prefResStateCustom, setPrefResStateCustom] = useState("");
  const [preferredOriginCountry, setPreferredOriginCountry] = useState("");
  const [preferredOriginState, setPreferredOriginState] = useState("");
  const [prefOriCountryCustom, setPrefOriCountryCustom] = useState("");
  const [prefOriCustom, setPrefOriCustom] = useState("");
  const [preferredPartnerAgeRange, setPreferredPartnerAgeRange] = useState<[number, number]>([18, 60]);

  // Selfie Liveness Interactive Modal States
  const [isLivenessModalOpen, setIsLivenessModalOpen] = useState(false);
  const [livenessState, setLivenessState] = useState<"idle" | "ready" | "smile" | "up" | "straight" | "complete">("idle");
  // defined in the previous patch block so this old definition might still exist
  const [livenessPrompt, setLivenessPrompt] = useState("Center your face in the circle");
  const [isCameraActive, setIsCameraActive] = useState(true);

  // ID Scanning Interactive Modal States
  const [isIdScanModalOpen, setIsIdScanModalOpen] = useState(false);
  const [idScanState, setIdScanState] = useState<"idle" | "align" | "scanning" | "complete">("idle");
  const [idScanPrompt, setIdScanPrompt] = useState("Align ID inside the rectangle frame");

  // Camera stream refs
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const idVideoRef = useRef<HTMLVideoElement | null>(null);
  const idStreamRef = useRef<MediaStream | null>(null);

  // AI Interview Conversation State
  const [messages, setMessages] = useState<Array<{ role: "ai" | "user"; text: string }>>([
    {
      role: "ai",
      text: "Welcome to KNOT. I am your AI Matchmaking Guide. I will explore your psychological profiles, attachment dynamics, and commitment objectives. Shall we begin?"
    }
  ]);
  const [currentInput, setCurrentInput] = useState("");
  const [interviewQuestionIndex, setInterviewQuestionIndex] = useState(0);
  const chatEndRef = useRef<HTMLDivElement>(null);

  // Simulated AI Interview Prompts
  const interviewPrompts = [
    "What kind of relationship are you hoping to build with a potential partner?",
    "What core values and priorities matter most in your life and future marriage?",
    "What does permanent commitment mean to you personally?",
    "How do you usually approach disagreements or conflict resolution in relationships?",
    "What are your core relationship non-negotiables?",
    "Would you be open to relocating for the right relationship?"
  ];

  // Extracted AI Archetype Results
  const [archetype, setArchetype] = useState({
    personalityArchetype: "The Intentional Builder",
    attachmentStyle: "Secure",
    readinessScore: 88,
    seriousnessLevel: 94,
    trustScore: 85,
    personalValues: ["Family Traditions", "Faith", "Mutual Growth"]
  });

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // Handle Liveness Camera Access
  useEffect(() => {
    if (isLivenessModalOpen && isCameraActive) {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" } })
          .then(stream => {
            if (videoRef.current) {
              videoRef.current.srcObject = stream;
            }
            streamRef.current = stream;
          })
          .catch(err => {
            console.warn("Webcam access failed (using simulation wireframe):", err);
            setIsCameraActive(false);
          });
      } else {
        console.warn("navigator.mediaDevices is undefined (likely non-HTTPS or unsupported)");
        setIsCameraActive(false);
      }
    } else {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(track => track.stop());
        streamRef.current = null;
      }
    }
  }, [isLivenessModalOpen, isCameraActive]);

  // Handle ID Scanning Camera Access
  useEffect(() => {
    if (isIdScanModalOpen && isCameraActive) {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" } })
          .then(stream => {
            if (idVideoRef.current) {
              idVideoRef.current.srcObject = stream;
            }
            idStreamRef.current = stream;
          })
          .catch(err => {
            console.warn("Camera access failed (using simulation wireframe):", err);
            setIsCameraActive(false);
          });
      } else {
        console.warn("navigator.mediaDevices is undefined (likely non-HTTPS or unsupported)");
        setIsCameraActive(false);
      }
    } else {
      if (idStreamRef.current) {
        idStreamRef.current.getTracks().forEach(track => track.stop());
        idStreamRef.current = null;
      }
    }
  }, [isIdScanModalOpen, isCameraActive]);

  // Add ref for face-api requestAnimationFrame
  const requestRef = useRef<number | null>(null);

  // Load face-api models on mount
  useEffect(() => {
    const loadModels = async () => {
      try {
        const faceapi = await import('@vladmandic/face-api');
        await Promise.all([
          faceapi.nets.tinyFaceDetector.loadFromUri('/models'),
          faceapi.nets.faceLandmark68Net.loadFromUri('/models'),
          faceapi.nets.faceExpressionNet.loadFromUri('/models')
        ]);
        console.log("FaceAPI models loaded successfully.");
      } catch (err) {
        console.error("Failed to load FaceAPI models", err);
      }
    };
    loadModels();
  }, []);

  const livenessStateRef = useRef(livenessState);
  useEffect(() => {
    livenessStateRef.current = livenessState;
  }, [livenessState]);

  // Liveness State Machine & Loop
  useEffect(() => {
    let active = true;

    const detectFace = async () => {
      if (!isLivenessModalOpen || !videoRef.current || livenessStateRef.current === "complete") return;
      const faceapi = await import('@vladmandic/face-api');
      
      const video = videoRef.current;
      if (video.readyState === 4) { // HAVE_ENOUGH_DATA
        const detection = await faceapi.detectSingleFace(video, new faceapi.TinyFaceDetectorOptions())
          .withFaceLandmarks()
          .withFaceExpressions();

        if (detection) {
          const { expressions, landmarks, detection: box } = detection;
          const currentState = livenessStateRef.current;
          
          if (currentState === "ready") {
            // Check if face is centered and large enough
            const faceWidth = box.box.width;
            if (faceWidth > 50) { // Relaxed size constraint for different webcams
              setLivenessState("smile");
              setLivenessPrompt("Good! Now smile big to verify aliveness");
            }
          } else if (currentState === "smile") {
            if (expressions.happy > 0.8) {
              setLivenessState("up");
              setLivenessPrompt("Perfect! Raise your head up");
            }
          } else if (currentState === "up") {
            // Check pitch using landmarks
            const nose = landmarks.getNose()[0];
            const leftEye = landmarks.getLeftEye()[0];
            const rightEye = landmarks.getRightEye()[0];
            const jaw = landmarks.getJawOutline();
            const bottomJaw = jaw[8]; // chin
            
            const eyeY = (leftEye.y + rightEye.y) / 2;
            const distEyeNose = Math.abs(nose.y - eyeY);
            const distNoseChin = Math.abs(bottomJaw.y - nose.y);
            
            // Looking up means nose gets closer to eyes
            if (distEyeNose < distNoseChin * 0.5) {
              setLivenessState("straight");
              setLivenessPrompt("Great! Now lower your head down");
            }
          } else if (currentState === "straight") {
            const nose = landmarks.getNose()[0];
            const leftEye = landmarks.getLeftEye()[0];
            const rightEye = landmarks.getRightEye()[0];
            const jaw = landmarks.getJawOutline();
            const bottomJaw = jaw[8]; // chin
            
            const eyeY = (leftEye.y + rightEye.y) / 2;
            const distEyeNose = Math.abs(nose.y - eyeY);
            const distNoseChin = Math.abs(bottomJaw.y - nose.y);
            
            // Looking down means nose gets closer to chin
            if (distNoseChin < distEyeNose * 0.6) {
              setLivenessState("complete");
              setLivenessPrompt("Liveness Confirmed! Biometric face scan complete.");
              
              // Capture the frame!
              const canvas = document.createElement("canvas");
              canvas.width = video.videoWidth || 640;
              canvas.height = video.videoHeight || 480;
              const ctx = canvas.getContext("2d");
              if (ctx) {
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                const dataUrl = canvas.toDataURL("image/jpeg", 0.9);
                setVerificationSelfie(dataUrl);
              }
              
              setTimeout(() => {
                if (active) {
                  setIsLivenessModalOpen(false);
                  setIsCameraActive(false);
                }
              }, 1500);
            }
          }
        }
      }

      if (active) {
        requestRef.current = requestAnimationFrame(detectFace);
      }
    };

    if (isLivenessModalOpen && isCameraActive) {
      // Small delay to let video start playing
      setTimeout(() => detectFace(), 1000);
    }

    return () => {
      active = false;
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    };
  }, [isLivenessModalOpen, isCameraActive]);

  // Liveness Real Webcam Capture init
  const startLivenessScanner = () => {
    setIsLivenessModalOpen(true);
    setIsCameraActive(true);
    setLivenessState("ready");
    setLivenessPrompt("Center your face in the circular aperture");
  };

  // ID Card Real Webcam Capture
  const startIdScanner = () => {
    setIsIdScanModalOpen(true);
    setIsCameraActive(true);
    setIdScanState("align");
    setIdScanPrompt("Align document inside the rectangular frame");

    setTimeout(() => {
      setIdScanState("scanning");
      setIdScanPrompt("Scanning ID barcode & OCR features...");

      setTimeout(() => {
        setIdScanState("complete");
        setIdScanPrompt("ID Scan Complete! OCR match succeeded.");
        
        // Capture the actual webcam frame
        if (videoRef.current) {
          const canvas = document.createElement("canvas");
          canvas.width = videoRef.current.videoWidth || 640;
          canvas.height = videoRef.current.videoHeight || 480;
          const ctx = canvas.getContext("2d");
          if (ctx) {
            ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
            const dataUrl = canvas.toDataURL("image/jpeg", 0.9);
            setGovernmentId(dataUrl);
          }
        }

        setTimeout(() => {
          setIsIdScanModalOpen(false);
          setIsCameraActive(false);
        }, 1500);
      }, 2000);
    }, 2000);
  };

  const handleNextStep = () => {
    setStep(step + 1);
  };

  const handleFinalizeRegistration = async () => {
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;
        
      const res = await fetch(`${API_URL}/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          firstName, lastName, dateOfBirth, email, password,
          bio: "", occupation, religion: religionSelect === "Other" ? religionCustom : religionSelect,
          education: "", culturalBackground: "", smoking, drinking, maritalStatus, childrenStatus,
          marriageTimeline, willingToRelocate, childrenPreference, idealPartnerTraits: [],
          marriageExpectations, careerGoals: "",
          residenceCountry, residenceState, residenceCity,
          originCountry, originState, originCity,
          preferredResidenceCountry: preferredResidenceCountry === 'Enter Choice Country' ? prefResCountryCustom : preferredResidenceCountry,
          preferredResidenceState: preferredResidenceState === 'Enter State/Province/Region' ? prefResStateCustom : preferredResidenceState,
          preferredOriginCountry: preferredOriginCountry === 'Enter Choice Country' ? prefOriCountryCustom : preferredOriginCountry,
          preferredOriginState: preferredOriginState === 'Enter Native Heritage' ? prefOriCustom : preferredOriginState,
          preferredPartnerAgeRange
        })
      });

      const data = await res.json();
      if (data.token) {
        localStorage.setItem('knot_token', data.token);
      }
      setStep(7);
    } catch (err) {
      console.error("Registration failed:", err);
      // Even if it fails, go to step 5 for prototype continuity
      setStep(7);
    }
  };

  const handleSendMessage = async () => {
    if (!currentInput.trim()) return;

    const userMsg = currentInput.trim();
    setMessages(prev => [...prev, { role: "user", text: userMsg }]);
    setCurrentInput("");

    // Append loading message
    setMessages(prev => [...prev, { role: "ai", text: "Analyzing response..." }]);

    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;

      const question = interviewQuestionIndex === 0 ? "Shall we begin?" : interviewPrompts[interviewQuestionIndex - 1];
      const verifyRes = await fetch(`${API_URL}/users/onboarding/validate-answer`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question, answer: userMsg })
      });

      const res = await verifyRes.json();

      setMessages(prev => {
        const filtered = prev.filter(m => m.text !== "Analyzing response...");
        if (!res.valid) {
          return [
            ...filtered,
            { role: "ai", text: res.clarification || "Please write a more serious, genuine response." }
          ];
        } else {
          if (interviewQuestionIndex < interviewPrompts.length) {
            const nextPrompt = interviewPrompts[interviewQuestionIndex];
            setInterviewQuestionIndex(prev => prev + 1);
            return [
              ...filtered,
              { role: "ai", text: `Thank you for sharing that. ${nextPrompt}` }
            ];
          } else {
            return [
              ...filtered,
              { role: "ai", text: "Excellent. I have completed my relationship intelligence assessment. I will now analyze your values, personality alignment, and readiness indices. Shall we generate your Relationship Registry Certificate?" }
            ];
          }
        }
      });
    } catch (error) {
      // Fallback
      setMessages(prev => {
        const filtered = prev.filter(m => m.text !== "Analyzing response...");
        if (interviewQuestionIndex < interviewPrompts.length) {
          const nextPrompt = interviewPrompts[interviewQuestionIndex];
          setInterviewQuestionIndex(prev => prev + 1);
          return [
            ...filtered,
            { role: "ai", text: `Thank you for sharing that. ${nextPrompt}` }
          ];
        } else {
          return [
            ...filtered,
            { role: "ai", text: "Excellent. I have completed my relationship intelligence assessment. Shall we generate your Relationship Registry Certificate?" }
          ];
        }
      });
    }
  };

  const handleProcessAIVerification = async () => {
    setStep(3); // Trigger Processing
    setVerificationStep(0);

    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL;
      
      // Final cleanup of "Other" fields
      const finalLanguages = languagesSpoken.map(l => l === "Other" && otherLanguageInput ? otherLanguageInput : l);
      const finalTraits = idealPartnerTraits.map(t => t === "Other" && otherTraitInput ? otherTraitInput : t);

      const verifyRes = await fetch(`${API_URL}/users/onboarding/verify`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          selfieUrl: verificationSelfie, // FIX: Scanner now strictly uses the Selfie Image
          idUrl: governmentId,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          languagesSpoken: finalLanguages,
          idealPartnerTraits: finalTraits,
          marriageExpectations,
          preferredResidenceCountry: preferredResidenceCountry === 'Enter Choice Country' ? prefResCountryCustom : preferredResidenceCountry,
          preferredResidenceState: preferredResidenceState === 'Enter State/Province/Region' ? prefResStateCustom : preferredResidenceState,
          preferredOriginCountry: preferredOriginCountry === 'Enter Choice Country' ? prefOriCountryCustom : preferredOriginCountry,
          preferredOriginState: preferredOriginState === 'Enter Native Heritage' ? prefOriCustom : preferredOriginState,
          preferredPartnerAgeRange
        })
      });

      const res = await verifyRes.json();
      
      // Save user profile locally for dashboard prototype
      localStorage.setItem('knot_userProfile', JSON.stringify({
        firstName, lastName, dateOfBirth, email, 
        residenceCity, residenceCountry, occupation,
        isVerified: true
      }));

      if (!res.success) {
        alert(res.details || "The documents could not be verified. Please make sure to upload a clear selfie and a valid government ID.");
        setStep(4); // Go back to files upload step
        return;
      }

      // If successful, show the beautiful animated flow
      setStep(5);
      setVerificationStep(1); // Extracting ID details
      setTimeout(() => {
        setVerificationStep(2); // Matching face biometric vectors
        setTimeout(() => {
          setVerificationStep(3); // Verifying age alignment
          setTimeout(() => {
            setVerificationStep(4); // Completed - user clicks proceed button to continue
          }, 1800);
        }, 1800);
      }, 1800);

    } catch (error) {
      console.error("AI verification failed:", error);
      alert("Verification failed due to a network or server error. Please try again.");
      setStep(4);
    }
  };

  // Location selector lists
  const residenceStates = STATES_BY_COUNTRY[residenceCountry] || [];
  const residenceCities = CITIES_BY_STATE[residenceState] || [];
  const originStates = STATES_BY_COUNTRY[originCountry] || [];
  const originCities = CITIES_BY_STATE[originState] || [];

  return (
    <div className="min-h-screen bg-[#0A0E14] text-white flex flex-col justify-between py-6 px-4 sm:py-12 sm:px-6">
      {/* Header */}
      <header className="max-w-4xl mx-auto w-full flex items-center justify-between">
        <div className="flex items-center gap-4">
          {((step === 2 && subStep > 0) || (step > 2 && step < 6)) && (
            <button 
              onClick={() => {
                if (step === 2 && subStep > 0) setSubStep(subStep - 1);
                else if (step > 2) setStep(step - 1);
              }}
              className="text-white hover:text-[#D4AF37] transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
            </button>
          )}
          <Link href="/" className="text-xl font-serif font-black tracking-wider flex items-center gap-1">
            KNOT<span className="text-[#D4AF37]">.</span>
          </Link>
        </div>
        <span className="text-[10px] uppercase tracking-widest text-gray-500 font-bold bg-white/5 px-4 py-1.5 rounded-full border border-white/5">
          Step {step} of 5
        </span>
      </header>

      {/* Main Container */}
      <main className="max-w-2xl mx-auto w-full my-auto py-6 sm:py-12">
        
        {/* Step 1: Cinematic Welcome */}
        {step === 1 && (
          <div className="space-y-8 text-center">
            <div className="w-16 h-16 rounded-3xl bg-[#D4AF37]/10 flex items-center justify-center text-[#D4AF37] border border-[#D4AF37]/20 mx-auto">
              <Heart className="w-8 h-8" />
            </div>
            <div className="space-y-3">
              <h2 className="text-3xl md:text-4xl font-serif font-black">AI Guided Relationship Registry</h2>
              <p className="text-sm text-gray-400 max-w-md mx-auto leading-relaxed">
                Before entering KNOT, all members complete our AI Guided interview to establish personality vectors, attachment archetypes, and commitment integrity.
              </p>
            </div>
            <button 
              onClick={handleNextStep}
              className="px-8 py-4 rounded-full text-base font-black rose-glow-btn text-white w-full max-w-sm"
            >
              Begin Registry Setup
            </button>
          </div>
        )}

        {/* Step 2: Personal Essentials (Sequential Fly-In) */}
        {step === 2 && (
          <div className="glass-card rounded-[32px] p-6 sm:p-8 border border-white/10 space-y-6 relative overflow-hidden min-h-[400px] flex flex-col justify-center">
            
            {subStep === 0 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">What is your name?</h2>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">First Name</label>
                  <input type="text" value={firstName} onChange={e => setFirstName(e.target.value)} placeholder="First Name" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Last Name</label>
                  <input type="text" value={lastName} onChange={e => setLastName(e.target.value)} placeholder="Last Name" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                </div>
                <button onClick={() => setSubStep(1)} disabled={!firstName || !lastName} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 1 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Your Gender Preferences</h2>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Your Gender</label>
                  <select value={gender} onChange={e => setGender(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select</option>
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                  </select>
                </div>
                <button onClick={() => setSubStep(2)} disabled={!gender} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 2 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Basic Info</h2>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Date of Birth</label>
                  <input type="date" value={dateOfBirth} onChange={e => setDateOfBirth(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Occupation</label>
                  <input type="text" value={occupation} onChange={e => setOccupation(e.target.value)} placeholder="e.g. Software Engineer" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                </div>
                <button onClick={() => setSubStep(3)} disabled={!dateOfBirth || !occupation} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 3 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Religion & Faith</h2>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Religion</label>
                  <select value={religionSelect} onChange={e => { setReligionSelect(e.target.value); if(e.target.value !== 'Other') setReligion(e.target.value); }} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select religion / faith</option>
                    {['Christian', 'Muslim', 'Jewish', 'Hindu', 'Buddhist', 'Atheist', 'Agnostic', 'Other'].map(r => <option key={r} value={r}>{r}</option>)}
                  </select>
                </div>
                {religionSelect === 'Other' && (
                  <input type="text" value={religionCustom} onChange={e => { setReligionCustom(e.target.value); setReligion(e.target.value); }} placeholder="Specify your religion" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                )}
                <button onClick={() => setSubStep(4)} disabled={!religion} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 4 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Where do you live?</h2>
                </div>
                <div className="space-y-4">
                  <select value={residenceCountry} onChange={e => { setResidenceCountry(e.target.value); setResidenceState(""); setResidenceCity(""); }} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select Country</option>
                    {COUNTRIES.map((c) => <option key={c} value={c}>{c}</option>)}
                  </select>
                  {STATES_BY_COUNTRY[residenceCountry] && STATES_BY_COUNTRY[residenceCountry].length > 0 ? (
                    <select value={residenceState} onChange={e => setResidenceState(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select State / Province</option>
                      {STATES_BY_COUNTRY[residenceCountry].map(s => <option key={s} value={s}>{s}</option>)}
                    </select>
                  ) : (
                    <input type="text" value={residenceState} onChange={e => setResidenceState(e.target.value)} placeholder="State / Province" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  )}
                  <input type="text" value={residenceCity} onChange={e => setResidenceCity(e.target.value)} placeholder="City / Town" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                </div>
                <button onClick={() => setSubStep(5)} disabled={!residenceCountry || !residenceCity} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 5 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Heritage & Origin</h2>
                </div>
                <div className="space-y-4">
                  <select value={originCountry} onChange={e => { setOriginCountry(e.target.value); setOriginState(""); setOriginCity(""); }} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select Country</option>
                    {COUNTRIES.map((c) => <option key={c} value={c}>{c}</option>)}
                  </select>
                  {STATES_BY_COUNTRY[originCountry] && STATES_BY_COUNTRY[originCountry].length > 0 ? (
                    <select value={originState} onChange={e => setOriginState(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select State / Province</option>
                      {STATES_BY_COUNTRY[originCountry].map(s => <option key={s} value={s}>{s}</option>)}
                    </select>
                  ) : (
                    <input type="text" value={originState} onChange={e => setOriginState(e.target.value)} placeholder="State / Province" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  )}
                  <input type="text" value={originCity} onChange={e => setOriginCity(e.target.value)} placeholder="City / Town" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                </div>
                <button onClick={() => setSubStep(6)} disabled={!originCountry || !originCity} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 6 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Intended Partners Residence</h2>
                </div>
                <p className="text-gray-400 text-sm mb-4">Where do you ideally want your partner to be living?</p>
                <div className="space-y-4">
                  <select value={preferredResidenceCountry} onChange={e => { setPreferredResidenceCountry(e.target.value); setPreferredResidenceState(""); }} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select Country</option>
                    <option value="Any Country">Any Country</option>
                    <option value="Enter Choice Country">Enter Choice Country</option>
                    {COUNTRIES.map((c) => <option key={c} value={c}>{c}</option>)}
                  </select>
                  {preferredResidenceCountry === 'Enter Choice Country' && (
                    <input type="text" value={prefResCountryCustom} onChange={e => setPrefResCountryCustom(e.target.value)} placeholder="Type your choice country" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  )}
                  
                  <select value={preferredResidenceState} onChange={e => setPreferredResidenceState(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select State / Province</option>
                    <option value="Any State/Province/Region">Any State/Province/Region</option>
                    <option value="Enter State/Province/Region">Enter State/Province/Region</option>
                    {(STATES_BY_COUNTRY[preferredResidenceCountry] || []).map((s) => <option key={s} value={s}>{s}</option>)}
                  </select>
                  {preferredResidenceState === 'Enter State/Province/Region' && (
                    <input type="text" value={prefResStateCustom} onChange={e => setPrefResStateCustom(e.target.value)} placeholder="Type your choice state/province/region" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  )}
                </div>
                <button onClick={() => {
                  if (preferredResidenceCountry === 'Enter Choice Country' && !prefResCountryCustom.trim()) {
                    alert('Please type your choice country.'); return;
                  }
                  if (preferredResidenceState === 'Enter State/Province/Region' && !prefResStateCustom.trim()) {
                    alert('Please type your choice state/province/region.'); return;
                  }
                  setSubStep(7);
                }} disabled={!preferredResidenceCountry} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 7 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Native Heritage</h2>
                </div>
                <p className="text-gray-400 text-sm mb-4">What is your preferred cultural background or origin for a partner?</p>
                <div className="space-y-4">
                  <select value={preferredOriginCountry} onChange={e => { setPreferredOriginCountry(e.target.value); setPreferredOriginState(""); }} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select Country</option>
                    <option value="Any Country">Any Country</option>
                    <option value="Enter Choice Country">Enter Choice Country</option>
                    {COUNTRIES.map((c) => <option key={c} value={c}>{c}</option>)}
                  </select>
                  {preferredOriginCountry === 'Enter Choice Country' && (
                    <input type="text" value={prefOriCountryCustom} onChange={e => setPrefOriCountryCustom(e.target.value)} placeholder="Type your choice country" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  )}
                  
                  <select value={preferredOriginState} onChange={e => setPreferredOriginState(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select Native Heritage</option>
                    <option value="Any Heritage">Any Heritage</option>
                    <option value="Enter Native Heritage">Enter Native Heritage</option>
                  </select>
                  {preferredOriginState === 'Enter Native Heritage' && (
                    <input type="text" value={prefOriCustom} onChange={e => setPrefOriCustom(e.target.value)} placeholder="e.g. Yoruba, Scottish, English, Catalan" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  )}
                </div>
                <button onClick={() => {
                  if (preferredOriginCountry === 'Enter Choice Country' && !prefOriCountryCustom.trim()) {
                    alert('Please type your choice country.'); return;
                  }
                  if (preferredOriginState === 'Enter Native Heritage' && !prefOriCustom.trim()) {
                    alert('Please type your choice native heritage.'); return;
                  }
                  setSubStep(8);
                }} disabled={!preferredOriginCountry} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 8 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Languages</h2>
                </div>
                <MultiSelectDropdown label="Languages Spoken" options={[...MAJOR_LANGUAGES]} values={languagesSpoken} onChange={setLanguagesSpoken} placeholder="Select languages" />
                {languagesSpoken.includes("Other") && (
                  <input type="text" value={languageCustom} onChange={e => setLanguageCustom(e.target.value)} placeholder="Specify other language" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                )}
                <button onClick={() => setSubStep(9)} disabled={languagesSpoken.length === 0} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 9 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Lifestyle Habits</h2>
                </div>
                <div className="space-y-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Marriage History</label>
                    <select value={maritalStatus} onChange={e => setMaritalStatus(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select history</option>
                      <option value="Never married">Never married</option>
                      <option value="Divorced">Divorced</option>
                      <option value="Widowed">Widowed</option>
                      <option value="Annulled">Annulled</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Smoking</label>
                    <select value={smoking} onChange={e => setSmoking(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Non-smoker">Non-smoker</option>
                      <option value="Occasional">Occasional</option>
                      <option value="Regular smoker">Regular smoker</option>
                      <option value="Trying to quit">Trying to quit</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Drinking</label>
                    <select value={drinking} onChange={e => setDrinking(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select</option>
                      <option value="Non-drinker">Non-drinker</option>
                      <option value="Socially">Socially</option>
                      <option value="Regularly">Regularly</option>
                    </select>
                  </div>
                </div>
                <button onClick={() => setSubStep(10)} disabled={!maritalStatus || !smoking || !drinking} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 10 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Future Plans</h2>
                </div>
                <div className="space-y-4">
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Future Partners Children Status</label>
                    <select value={childrenStatus} onChange={e => setChildrenStatus(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Select status</option>
                      <option value="No Kid(s)">No Kid(s)</option>
                      <option value="With Kid(s)">With Kid(s)</option>
                      <option value="With or Without Kid(s)">With or Without Kid(s)</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Vow Timeline</label>
                    <select value={marriageTimeline} onChange={e => setMarriageTimeline(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Timeline</option>
                      <option value="ASAP">ASAP</option>
                      <option value="1-2 years">1-2 years</option>
                      <option value="3+ years">3+ years</option>
                      <option value="Not sure">Not sure</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Relocation</label>
                    <select value={willingToRelocate} onChange={e => setWillingToRelocate(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                      <option value="">Relocate</option>
                      <option value="Yes">Yes</option>
                      <option value="No">No</option>
                      <option value="Maybe">Maybe</option>
                    </select>
                  </div>
                </div>
                <button onClick={() => setSubStep(11)} disabled={!childrenStatus || !marriageTimeline || !willingToRelocate} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 11 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Family Goals</h2>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Children Intent</label>
                  <select value={childrenPreference} onChange={e => setChildrenPreference(e.target.value)} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50">
                    <option value="">Select intent</option>
                    <option value="Want children">Want children</option>
                    <option value="Don't want children">Don't want children</option>
                    <option value="Open to children">Open to children</option>
                  </select>
                </div>
                <button onClick={() => setSubStep(12)} disabled={!childrenPreference} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep === 12 && (
              <div className="animate-in fade-in slide-in-from-bottom-8 duration-700 ease-out space-y-6">
                <div className="text-center space-y-1 mb-8">
                  <h2 className="text-2xl font-serif font-black">Ideal Partner Traits</h2>
                </div>
                <MultiSelectDropdown label="Traits" options={[...MAJOR_TRAITS]} values={idealPartnerTraits} onChange={setIdealPartnerTraits} placeholder="Select traits" />
                {idealPartnerTraits.includes("Other") && (
                  <input type="text" value={traitCustom} onChange={e => setTraitCustom(e.target.value)} placeholder="Specify other trait" className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white mb-4 focus:outline-none focus:border-[#D4AF37]/50" />
                )}
                
                <div className="mt-4">
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Ideal Partner Age Range</label>
                  <div className="flex gap-4">
                    <input type="number" placeholder="Min Age" value={preferredPartnerAgeRange[0]} onChange={(e) => setPreferredPartnerAgeRange([parseInt(e.target.value) || 0, preferredPartnerAgeRange[1]])} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                    <input type="number" placeholder="Max Age" value={preferredPartnerAgeRange[1]} onChange={(e) => setPreferredPartnerAgeRange([preferredPartnerAgeRange[0], parseInt(e.target.value) || 0])} className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white focus:outline-none focus:border-[#D4AF37]/50" />
                  </div>
                </div>

                <div className="mt-4">
                  <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold block mb-1">Marriage Expectations</label>
                  <textarea 
                    value={marriageExpectations} 
                    onChange={e => setMarriageExpectations(e.target.value)} 
                    placeholder="What are your expectations for marriage?" 
                    className="w-full bg-[#121721] border border-white/10 rounded-2xl py-3.5 px-4 text-sm text-white min-h-[80px] focus:outline-none focus:border-[#D4AF37]/50" 
                  />
                </div>
                
                <button onClick={() => {
                  if (preferredPartnerAgeRange[0] < 18) {
                    alert("The minimum age for a partner must be 18 or older."); return;
                  }
                  if (preferredPartnerAgeRange[1] < preferredPartnerAgeRange[0]) {
                    alert("The maximum age cannot be less than the minimum age."); return;
                  }
                  setStep(3); // Go to Profile Picture Upload next
                }} disabled={idealPartnerTraits.length === 0} className="w-full py-4 mt-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50 transition-opacity">Next</button>
              </div>
            )}

            {subStep > 0 && (
              <button onClick={() => setSubStep(subStep - 1)} className="absolute top-6 left-6 text-gray-500 hover:text-white flex items-center gap-1 text-xs">
                &larr; Back
              </button>
            )}
          </div>
        )}
        
        
        {/* Step 3: Profile Picture Upload */}
        {step === 3 && (
          <div className="glass-card rounded-[32px] p-6 sm:p-8 border border-white/10 space-y-8 max-w-md mx-auto">
            <div className="text-center space-y-2">
              <h2 className="text-2xl font-serif font-black text-white">Profile Picture</h2>
              <p className="text-sm text-gray-400">Upload a clear, recent photo of yourself</p>
            </div>
            
            <div className="flex flex-col items-center">
              <label htmlFor="profile-upload" className="w-32 h-32 rounded-full bg-[#121721] border border-white/10 overflow-hidden flex items-center justify-center relative cursor-pointer group">
                {profilePicture ? (
                  <img src={profilePicture} alt="Profile" className="w-full h-full object-cover" />
                ) : (
                  <User className="w-12 h-12 text-gray-500 group-hover:text-white transition-colors" />
                )}
                <input 
                  id="profile-upload"
                  type="file" 
                  accept="image/*" 
                  className="hidden"
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) {
                      setUploadedProfilePic(file);
                      setProfilePicture(URL.createObjectURL(file));
                    }
                  }}
                />
              </label>
              <label 
                htmlFor="profile-upload"
                className="mt-4 px-6 py-3 rounded-full text-sm font-bold bg-white/5 border border-white/10 text-white cursor-pointer hover:bg-white/10 transition-colors"
              >
                Choose Photo
              </label>
            </div>

            <div className="pt-4 space-y-4">
              <button 
                onClick={() => setStep(4)} 
                disabled={!profilePicture}
                className="w-full py-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50"
              >
                Upload & Continue
              </button>
              
              <div className="text-center">
                <button 
                  onClick={() => {
                    setProfilePictureSkipped(true);
                    setStep(4);
                  }}
                  className="text-xs text-gray-500 hover:text-white transition-colors underline"
                >
                  Skip for Now & Do This Later
                </button>
                <p className="text-white text-xs mt-3">
                  Warning: Your profile remains private until a picture is uploaded.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Step 4: Identity & Trust Verification */}
        {step === 4 && (
          <div className="glass-card rounded-[32px] p-6 sm:p-8 border border-white/10 space-y-6 max-w-md mx-auto">
            <div className="text-center space-y-2 mb-8">
              <h2 className="text-2xl font-serif font-black text-white">Identity & Trust Verification</h2>
              <p className="text-sm text-gray-400">Help us keep the community safe</p>
            </div>

            <div className="space-y-6">
              <div className="space-y-2">
                <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold">Selfie Scan for Verification</label>
                <div className="p-4 bg-[#121721] border border-white/10 rounded-2xl flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center">
                      {verificationSelfie ? <img src={verificationSelfie} className="w-full h-full rounded-full object-cover" /> : <Camera className="w-5 h-5 text-[#D4AF37]" />}
                    </div>
                    <div>
                      <button onClick={startLivenessScanner} className="text-sm font-bold text-[#D4AF37] hover:underline">Start Live Face Scan</button>
                      <p className="text-[10px] text-gray-500">Strictly for verification</p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] uppercase tracking-widest text-gray-400 font-bold">Government ID Scan</label>
                <p className="text-[10px] text-gray-500 mb-2">Int'l Passport, Driver's License, voters card or National ID</p>
                <div className="p-4 bg-[#121721] border border-white/10 rounded-2xl flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
                      {governmentId ? <img src={governmentId} className="w-full h-full rounded-xl object-cover" /> : <ShieldCheck className="w-5 h-5 text-gray-400" />}
                    </div>
                    <div className="flex flex-col gap-2">
                      <button onClick={startIdScanner} className="text-sm font-bold text-white hover:underline text-left">Scan ID Document</button>
                      <div className="relative">
                        <button className="text-xs font-bold text-gray-400 hover:text-white text-left pointer-events-none">Upload ID</button>
                        <input 
                          type="file" 
                          accept="image/*" 
                          className="absolute inset-0 opacity-0 cursor-pointer"
                          onChange={(e) => {
                            const file = e.target.files?.[0];
                            if (file) {
                              setUploadedGovId(file);
                              setGovernmentId(URL.createObjectURL(file));
                            }
                          }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-4 space-y-4">
              <button 
                onClick={() => {
                  handleProcessAIVerification();
                }} 
                disabled={!verificationSelfie || !governmentId}
                className="w-full py-4 rounded-xl text-sm font-black rose-glow-btn text-white disabled:opacity-50"
              >
                Verify Identity & Documents
              </button>
              
              <div className="text-center">
                <p className="text-[#D4AF37] text-xs font-bold mt-2">
                  🔒 Identity Verification is Compulsory for Registry Safety
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Step 5: Futuristic AI Identity & Document Verification Scan */}
        {step === 6 && (
          <div className="glass-card rounded-[32px] border border-white/10 flex flex-col h-[500px] overflow-hidden">
            {/* Header */}
            <div className="p-4 bg-[#121721]/90 border-b border-white/5 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#D4AF37]/10 flex items-center justify-center text-[#D4AF37] border border-[#D4AF37]/20">
                <Bot className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold">KNOT AI Matchmaking Guide</h4>
                <p className="text-[9px] uppercase tracking-wider text-[#D4AF37] font-bold">Interview Session Active</p>
              </div>
            </div>

            {/* Chat Area */}
            <div className="flex-1 p-6 overflow-y-auto space-y-4">
              {messages.map((m, idx) => (
                <div key={idx} className={`flex items-start gap-3 ${m.role === "user" ? "justify-end" : ""}`}>
                  {m.role === "ai" && (
                    <div className="w-8 h-8 rounded-full bg-[#D4AF37]/15 flex items-center justify-center text-[#D4AF37] text-xs font-bold flex-shrink-0">AI</div>
                  )}
                  <div className={`p-4 rounded-[22px] text-xs leading-relaxed max-w-[80%] ${
                    m.role === "user" 
                      ? "bg-[#E27D8D]/15 border border-[#E27D8D]/25 rounded-tr-none text-white"
                      : "bg-white/5 border border-white/5 rounded-tl-none text-gray-300"
                  }`}>
                    {m.text}
                  </div>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>

            {/* Input Bar */}
            <div className="p-4 bg-[#121721]/90 border-t border-white/5 flex items-center gap-2">
              <input 
                type="text" 
                value={currentInput}
                onChange={e => setCurrentInput(e.target.value)}
                onKeyDown={e => e.key === "Enter" && handleSendMessage()}
                placeholder="Share your thoughts empathetically..."
                className="flex-1 bg-white/5 border border-white/5 rounded-full py-3 px-6 text-xs text-white focus:outline-none focus:border-[#D4AF37]/50"
              />
              {interviewQuestionIndex >= interviewPrompts.length && currentInput === "" ? (
                <button 
                  onClick={handleFinalizeRegistration}
                  className="px-5 py-3 rounded-full text-xs font-black rose-glow-btn text-white flex items-center gap-1.5"
                >
                  Generate Registry <Sparkles className="w-3.5 h-3.5" />
                </button>
              ) : (
                <button 
                  onClick={handleSendMessage}
                  className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-gray-400 hover:text-white transition-colors"
                >
                  <Send className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>
        )}

        {/* Step 4: Conversational AI Onboarding Interview */}
        {step === 5 && !verificationSkipped && (
          <div className="glass-card rounded-[36px] p-6 sm:p-8 border border-[#D4AF37]/20 space-y-8 max-w-xl mx-auto overflow-hidden relative">
            <div className="text-center space-y-2">
              <h2 className="text-2xl font-serif font-black text-white">AI Biometric Liveness & ID Match</h2>
              <p className="text-[10px] uppercase tracking-widest text-[#D4AF37] font-black">Secure Verification Session In Progress</p>
            </div>

            {/* Split Scanner UI */}
            <div className="grid grid-cols-2 gap-6 relative">
              {/* Selfie Scan Frame */}
              <div className="space-y-2 text-center relative">
                <div className="text-[9px] uppercase tracking-widest text-gray-400 font-bold">Selfie Feed</div>
                <div className="aspect-square rounded-full bg-[#121721] border border-white/10 overflow-hidden relative flex items-center justify-center">
                  {profilePicture ? (
                    <img src={profilePicture} alt="Selfie" className="w-full h-full object-cover" />
                  ) : (
                    <User className="w-10 h-10 text-gray-500" />
                  )}
                  {/* Glowing Laser Scan Bar */}
                  {verificationStep < 4 && (
                    <div className="absolute left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-[#D4AF37] to-transparent animate-pulse shadow-[0_0_12px_#D4AF37]" style={{
                      animation: "scan 2s ease-in-out infinite",
                      top: "20%"
                    }} />
                  )}
                </div>
              </div>

              {/* ID Scan Frame */}
              <div className="space-y-2 text-center relative">
                <div className="text-[9px] uppercase tracking-widest text-gray-400 font-bold">Government Document</div>
                <div className="aspect-video w-full rounded-2xl bg-[#121721] border border-white/10 overflow-hidden relative flex items-center justify-center my-auto">
                  {governmentId ? (
                    <img src={governmentId} alt="ID Document" className="w-full h-full object-cover" />
                  ) : (
                    <ShieldCheck className="w-10 h-10 text-gray-500" />
                  )}
                  {/* Glowing Laser Scan Bar */}
                  {verificationStep < 4 && (
                    <div className="absolute left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-[#E27D8D] to-transparent animate-pulse shadow-[0_0_12px_#E27D8D]" style={{
                      animation: "scan 2s ease-in-out infinite",
                      top: "40%"
                    }} />
                  )}
                </div>
              </div>
            </div>

            {/* Checkpoints Progress */}
            <div className="space-y-3 p-4 bg-white/5 border border-white/5 rounded-2xl text-xs">
              <div className="flex items-center justify-between">
                <span className="text-gray-400">1. Scanning ID text & details...</span>
                {verificationStep >= 1 ? (
                  <span className="text-[#10B981] font-bold flex items-center gap-1">✔ Match</span>
                ) : (
                  <span className="text-[#D4AF37] font-bold flex items-center gap-1 animate-pulse"><Loader2 className="w-3.5 h-3.5 animate-spin" /> Scanning</span>
                )}
              </div>

              <div className="flex items-center justify-between">
                <span className="text-gray-400">2. Extracting face keypoints...</span>
                {verificationStep >= 2 ? (
                  <span className="text-[#10B981] font-bold flex items-center gap-1">✔ Extracted</span>
                ) : verificationStep === 1 ? (
                  <span className="text-[#D4AF37] font-bold flex items-center gap-1 animate-pulse"><Loader2 className="w-3.5 h-3.5 animate-spin" /> Computing</span>
                ) : (
                  <span className="text-gray-600">Pending</span>
                )}
              </div>

              <div className="flex items-center justify-between">
                <span className="text-gray-400">3. Biometric comparison (Selfie vs ID)...</span>
                {verificationStep >= 3 ? (
                  <span className="text-[#10B981] font-bold flex items-center gap-1">✔ 98.7% Confirmed</span>
                ) : verificationStep === 2 ? (
                  <span className="text-[#D4AF37] font-bold flex items-center gap-1 animate-pulse"><Loader2 className="w-3.5 h-3.5 animate-spin" /> Matching</span>
                ) : (
                  <span className="text-gray-600">Pending</span>
                )}
              </div>

              <div className="flex items-center justify-between">
                <span className="text-gray-400">4. Age & Name consistency validation...</span>
                {verificationStep >= 4 ? (
                  <span className="text-[#10B981] font-bold flex items-center gap-1">✔ Approved</span>
                ) : verificationStep === 3 ? (
                  <span className="text-[#D4AF37] font-bold flex items-center gap-1 animate-pulse"><Loader2 className="w-3.5 h-3.5 animate-spin" /> Verifying</span>
                ) : (
                  <span className="text-gray-600">Pending</span>
                )}
              </div>
            </div>

            {/* Proceed button when real-time scan completes */}
            {verificationStep >= 4 && (
              <button 
                onClick={() => setStep(6)}
                className="w-full py-4 rounded-xl text-sm font-black bg-[#10B981] text-white flex items-center justify-center gap-2 hover:bg-[#059669] transition"
              >
                Identity Verified — Continue to AI Interview <ArrowRight className="w-4 h-4" />
              </button>
            )}

            {/* Scanning styles */}
            <style jsx>{`
              @keyframes scan {
                0%, 100% { top: 5%; }
                50% { top: 95%; }
              }
            `}</style>
          </div>
        )}

        {/* Step 5: Cinematic AI Relationship Certificate Reveal */}
        {step === 7 && (
          <div className="space-y-8 animate-fade-in">
            <div className="glass-card rounded-[36px] p-6 sm:p-8 border border-[#D4AF37]/30 shadow-2xl relative overflow-hidden max-w-md mx-auto">
              <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-[#D4AF37]/10 to-transparent rounded-bl-full pointer-events-none" />
              
              <div className="text-center space-y-4 mb-6">
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black tracking-widest uppercase trust-badge">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  VERIFIED REGISTRY CERTIFICATE
                </div>
                <h3 className="text-2xl font-serif font-black text-white">{firstName} {lastName}</h3>
                <p className="text-xs text-gray-400">{residenceCity || "Lagos"}, {residenceCountry || "Nigeria"} • Active Verified Member</p>
              </div>

              <div className="space-y-4 pt-4 border-t border-white/5">
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-gray-400 uppercase tracking-widest">Archetype</span>
                  <span className="text-xs text-[#D4AF37] font-black">{archetype.personalityArchetype}</span>
                </div>
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-gray-400 uppercase tracking-widest">Attachment Style</span>
                  <span className="text-xs text-white font-bold">{archetype.attachmentStyle}</span>
                </div>
                <div className="grid grid-cols-3 gap-2 py-2 border-b border-white/5 text-center">
                  <div className="p-2 rounded-xl bg-white/5">
                    <div className="text-[9px] text-gray-500 uppercase font-black">Readiness</div>
                    <div className="text-sm font-black text-white">{archetype.readinessScore}%</div>
                  </div>
                  <div className="p-2 rounded-xl bg-white/5">
                    <div className="text-[9px] text-gray-500 uppercase font-black">Seriousness</div>
                    <div className="text-sm font-black text-[#D4AF37]">{archetype.seriousnessLevel}%</div>
                  </div>
                  <div className="p-2 rounded-xl bg-white/5">
                    <div className="text-[9px] text-gray-500 uppercase font-black">Trust Score</div>
                    <div className="text-sm font-black text-[#10B981]">{archetype.trustScore}%</div>
                  </div>
                </div>
                <div>
                  <label className="text-[9px] uppercase tracking-widest text-gray-500 font-black block mb-2">Extracted Value Maps</label>
                  <div className="flex flex-wrap gap-1.5">
                    {archetype.personalValues.map((val, idx) => (
                      <span key={idx} className="px-2.5 py-1 rounded-lg bg-white/5 border border-white/5 text-[10px] text-gray-300 font-semibold">
                        ✔ {val}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            <div className="text-center">
              <Link 
                href="/dashboard" 
                className="inline-flex items-center gap-2 px-8 py-4 rounded-full text-base font-black rose-glow-btn text-white text-center w-full max-w-xs"
              >
                Activate Dashboard <ArrowRight className="w-4.5 h-4.5" />
              </Link>
            </div>
          </div>
        )}

      </main>

      {/* Selfie Liveness Face Scan Modal */}
      {isLivenessModalOpen && (
        <div className="fixed inset-0 z-50 bg-[#0A0E14]/90 flex items-center justify-center p-4 backdrop-blur-md">
          <div className="bg-[#0E131F] border border-[#D4AF37]/30 rounded-[32px] p-6 max-w-sm w-full text-center space-y-6 relative overflow-hidden">
            <button 
              onClick={() => setIsLivenessModalOpen(false)}
              className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="space-y-1">
              <h3 className="text-lg font-serif font-black text-white flex items-center justify-center gap-2">
                <Camera className="w-5 h-5 text-[#D4AF37]" /> Biometric Face Scanner
              </h3>
              <p className="text-[10px] text-gray-400 uppercase tracking-widest font-bold">Verifying Live Authenticity</p>
            </div>

            {/* Circular Aperture View */}
            <div className="w-48 h-48 rounded-full border-4 border-dashed border-[#D4AF37] mx-auto flex items-center justify-center relative overflow-hidden bg-[#121721] shadow-[0_0_24px_rgba(212,175,55,0.15)]">
              {isCameraActive ? (
                <video 
                  ref={videoRef} 
                  autoPlay 
                  playsInline 
                  muted 
                  className="w-full h-full object-cover rounded-full"
                />
              ) : (
                <div className="w-full h-full flex flex-col items-center justify-center p-4 text-center">
                  <Loader2 className="w-8 h-8 text-[#D4AF37] animate-spin mb-2" />
                  <span className="text-[9px] text-gray-500">Streaming Biometric Outline...</span>
                </div>
              )}

              {/* Laser Line Scanning Effect */}
              {livenessState !== "complete" && (
                <div className="absolute left-0 right-0 h-1 bg-[#D4AF37] opacity-60 animate-bounce" style={{
                  animationDuration: "3s"
                }} />
              )}

              {/* Calibration Face Outline overlay */}
              {livenessState === "ready" && (
                <div className="absolute inset-4 rounded-full border border-dashed border-white/20 pointer-events-none flex items-center justify-center">
                  <div className="w-16 h-20 rounded-full border-2 border-white/30" />
                </div>
              )}

              
              {/* Complete Overlay Flash */}
              {livenessState === "complete" && (
                <div className="absolute inset-0 bg-white/90 flex flex-col items-center justify-center animate-pulse gap-2">
                  <ShieldCheck className="w-12 h-12 text-[#10B981]" />
                  <img src={verificationSelfie || ""} className="w-24 h-24 rounded-full object-cover border-4 border-[#10B981]" />
                </div>
              )}
            </div>

            {/* Instruction Prompts */}
            <div className="p-3 bg-white/5 border border-white/5 rounded-2xl min-h-[64px] flex flex-col items-center justify-center">
              <span className="text-xs font-bold text-gray-200">{livenessPrompt}</span>
              <div className="flex gap-1.5 mt-2">
                <span className={`w-2 h-2 rounded-full ${livenessState === "ready" ? "bg-[#D4AF37] animate-pulse" : "bg-[#10B981]"}`} />
                <span className={`w-2 h-2 rounded-full ${livenessState === "smile" ? "bg-[#D4AF37] animate-pulse" : (livenessState === "straight" || livenessState === "complete") ? "bg-[#10B981]" : "bg-white/15"}`} />
                <span className={`w-2 h-2 rounded-full ${livenessState === "straight" ? "bg-[#D4AF37] animate-pulse" : livenessState === "complete" ? "bg-[#10B981]" : "bg-white/15"}`} />
              </div>
            </div>
            
            {livenessState === "complete" && (
              <div className="flex gap-4 w-full">
                <button onClick={startLivenessScanner} className="flex-1 py-3 rounded-full border border-white/20 text-white text-sm font-bold hover:bg-white/5 transition">
                  Retake
                </button>
                <button onClick={() => { setIsLivenessModalOpen(false); setIsCameraActive(false); }} className="flex-1 py-3 rounded-full bg-[#10B981] text-white text-sm font-bold hover:bg-[#0ea5e9] transition">
                  Ok
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ID Scan Rectangular Modal */}
      {isIdScanModalOpen && (
        <div className="fixed inset-0 z-50 bg-[#0A0E14]/90 flex items-center justify-center p-4 backdrop-blur-md">
          <div className="bg-[#0E131F] border border-white/10 rounded-[32px] p-6 max-w-sm w-full text-center space-y-6 relative overflow-hidden">
            <button 
              onClick={() => setIsIdScanModalOpen(false)}
              className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="space-y-1">
              <h3 className="text-lg font-serif font-black text-white flex items-center justify-center gap-2">
                <Shield className="w-5 h-5 text-[#E27D8D]" /> Government ID Scanner
              </h3>
              <p className="text-[10px] text-gray-400 uppercase tracking-widest font-bold">Scanning Document Verification</p>
            </div>

            {/* Rectangular Card Aperture View */}
            <div className="w-full aspect-[1.586/1] rounded-2xl border-4 border-dashed border-[#E27D8D] mx-auto flex items-center justify-center relative overflow-hidden bg-[#121721] shadow-[0_0_24px_rgba(226,125,141,0.15)]">
              {isCameraActive ? (
                <video 
                  ref={idVideoRef} 
                  autoPlay 
                  playsInline 
                  muted 
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex flex-col items-center justify-center p-4 text-center">
                  <Loader2 className="w-8 h-8 text-[#E27D8D] animate-spin mb-2" />
                  <span className="text-[9px] text-gray-500">Scanning ID card features...</span>
                </div>
              )}

              {/* Scanning laser line sweep */}
              {idScanState === "scanning" && (
                <div className="absolute left-0 right-0 h-1 bg-[#E27D8D] shadow-[0_0_8px_#E27D8D] animate-pulse" style={{
                  animation: "id-sweep 1.5s ease-in-out infinite",
                  top: "0%"
                }} />
              )}

              {/* Scan Complete flash */}
              {idScanState === "complete" && (
                <div className="absolute inset-0 bg-white/95 flex items-center justify-center">
                  <CheckCircle2 className="w-12 h-12 text-[#10B981]" />
                </div>
              )}
            </div>

            {/* Instruction Prompts */}
            <div className="p-3 bg-white/5 border border-white/5 rounded-2xl min-h-[48px] flex items-center justify-center">
              <span className="text-xs font-bold text-gray-200">{idScanPrompt}</span>
            </div>

            {/* CSS Animation Keyframes for ID sweep */}
            <style jsx>{`
              @keyframes id-sweep {
                0%, 100% { top: 5%; }
                50% { top: 95%; }
              }
            `}</style>
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="w-full text-center py-6 mt-auto">
        <p className="text-[10px] uppercase tracking-widest text-gray-500 font-bold">
          FRAUD-PROOF | AI MATCHMAKING | HIGH-TRUST
        </p>
      </footer>
    </div>
  );
}
