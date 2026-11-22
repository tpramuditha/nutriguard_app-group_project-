
const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
require("dotenv").config();

const app = express();

const PORT = Number(process.env.PORT) || 3000;
const HOST = "127.0.0.1";

const GROQ_URL =
  "https://api.groq.com/openai/v1/chat/completions";

const GROQ_MODEL = "qwen/qwen3.8-27b";

app.use(helmet());

// Accept Base64 images up to approximately 3 MB.
app.use(express.json({ limit: "5mb" }));

app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 30,
    standardHeaders: "draft-8",
    legacyHeaders: false,
  }),
);

// Existing health endpoint.
app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    app: "NutriGuard AI Backend",
    status: "running",
  });
});

// Real AI food recognition endpoint.
app.post("/api/recognize-food", async (req, res) => {
  const { imageBase64, mimeType } = req.body || {};

  const allowedTypes = [
    "image/jpeg",
    "image/png",
    "image/webp",
  ];

  if (
    typeof imageBase64 !== "string" ||
    typeof mimeType !== "string" ||
    !allowedTypes.includes(mimeType)
  ) {
    return res.status(400).json({
      success: false,
      message: "A valid food image is required.",
    });
  }

  // Accept raw Base64 only, not an entire data URL.
  if (
    !imageBase64 ||
    imageBase64.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(imageBase64)
  ) {
    return res.status(400).json({
      success: false,
      message: "Invalid image encoding.",
    });
  }

  const imageBuffer = Buffer.from(imageBase64, "base64");

  if (
    imageBuffer.length === 0 ||
    imageBuffer.length > 3 * 1024 * 1024
  ) {
    return res.status(400).json({
      success: false,
      message: "Image must be smaller than 3 MB.",
    });
  }

  // Verify the image signature, not just its MIME label.
  const isJpeg =
    mimeType === "image/jpeg" &&
    imageBuffer.length >= 3 &&
    imageBuffer[0] === 0xff &&
    imageBuffer[1] === 0xd8 &&
    imageBuffer[2] === 0xff;

  const isPng =
    mimeType === "image/png" &&
    imageBuffer.subarray(0, 8).equals(
      Buffer.from("89504e470d0a1a0a", "hex"),
    );

  const isWebp =
    mimeType === "image/webp" &&
    imageBuffer.toString("ascii", 0, 4) === "RIFF" &&
    imageBuffer.toString("ascii", 8, 12) === "WEBP";

  if (!isJpeg && !isPng && !isWebp) {
    return res.status(400).json({
      success: false,
      message: "Image content does not match its type.",
    });
  }

  if (!process.env.GROQ_API_KEY) {
    return res.status(503).json({
      success: false,
      message: "AI service is not configured.",
    });
  }

  
const prompt = `
You are a food image recognition assistant for NutriGuard,
a nutrition tracking application used in Sri Lanka.

TASK:
Identify the food items actually visible in the image.

SRI LANKAN FOOD CONTEXT:
The image may contain Sri Lankan dishes such as:
- Kottu Roti: chopped roti stir-fried with vegetables,
  often including egg, chicken, cheese, or other ingredients.
- Egg Hoppers (Biththara Appa): bowl-shaped hoppers
  with an egg in the center.
- Plain Hoppers (Appa): thin, bowl-shaped rice pancakes.
- String Hoppers (Idiyappam): thin strands of steamed
  rice-flour noodles arranged in nests.
- Pol Sambol: coconut-based condiment, often containing
  chili and onion.
- Lunu Miris: chili and onion condiment.
- Rice and Curry: rice served with separate curry dishes.
- Pittu, Kiribath, Dhal Curry, and other local meals.

IMPORTANT IDENTIFICATION RULES:
1. Consider Sri Lankan foods when the visual features fit.
2. Do not assume that every meal is Sri Lankan.
3. Do not label Kottu Roti as Korean Japchae merely
   because both dishes contain thin or chopped pieces.
4. Distinguish Hoppers from String Hoppers using
   their visible structure.
5. Distinguish side dishes when their appearance allows it.
6. Do not identify invisible ingredients as confirmed.
7. For mixed dishes, identify the whole dish when possible.
   Do not duplicate ingredients as separate foods unless
   they are clearly separate portions.
8. Do not invent brand names or precise recipes.
9. When uncertain, use a general name and explain why.
10. An image alone cannot establish precise nutrition,
    portion weight, or medical suitability.

CONFIDENCE:
Use "high" for visually distinctive food,
"medium" for plausible but uncertain identification,
and "low" for ambiguous identification.

These confidence categories are subjective model
assessments, not verified probabilities.

OUTPUT:
Return ONLY a valid JSON object in this structure:

{
  "foods": [
    {
      "name": "Most appropriate food name",
      "alternative_names": [],
      "visible_ingredients": [],
      "confidence": "medium"
    }
  ],
  "uncertainties": []
}

Additional rules:
- Include multiple foods when separate dishes are visible.
- Use common English names where possible.
- Include Sinhala or local food names as alternatives
  when appropriate and reasonably certain.
- Keep visible_ingredients limited to visually
  identifiable components.
- Describe important uncertainty in uncertainties.
- Return an empty foods array if no food is visible.
- Do not return Markdown or explanatory text
  outside the JSON object.
`;


  try {
    const imageUrl =
      `data:${mimeType};base64,${imageBase64}`;

    const response = await fetch(GROQ_URL, {
      method: "POST",
      signal: AbortSignal.timeout(60000),
      headers: {
        Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: prompt,
              },
              {
                type: "image_url",
                image_url: {
                  url: imageUrl,
                },
              },
            ],
          },
        ],
        response_format: {
          type: "json_object",
        },
        reasoning_effort: "none",
        temperature: 0.2,
        max_completion_tokens: 1200,
        stream: false,
      }),
    });

    if (!response.ok) {
      console.error(
        "Groq request failed with HTTP",
        response.status,
      );

      return res.status(502).json({
        success: false,
        message: "Food recognition service unavailable.",
      });
    }

    const groqData = await response.json();

    const content =
      groqData.choices?.[0]?.message?.content;

    if (typeof content !== "string") {
      throw new Error("Missing Groq response content.");
    }

    const result = JSON.parse(content);

    if (
      !result ||
      !Array.isArray(result.foods)
    ) {
      throw new Error("Invalid recognition result.");
    }

    // Validate food entries before returning them.
    for (const food of result.foods) {
      if (
        !food ||
        typeof food.name !== "string" ||
        !food.name.trim()
      ) {
        throw new Error("Invalid recognized food.");
      }
    }

    return res.status(200).json({
      success: true,
      foods: result.foods,
      uncertainties: Array.isArray(result.uncertainties)
        ? result.uncertainties
        : [],
    });
  } catch (error) {
    console.error(
      "Food recognition failed:",
      error.name || "Error",
    );

    return res.status(502).json({
      success: false,
      message: "Unable to recognize this food image.",
    });
  }
});

// Handle unknown routes.
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Endpoint not found.",
  });
});

app.listen(PORT, HOST, () => {
  console.log("--------------------------------");
  console.log("NutriGuard AI Backend Started");
  console.log(`URL: http://${HOST}:${PORT}`);
  console.log(`Health: http://${HOST}:${PORT}/health`);
  console.log(
    `Recognition: POST http://${HOST}:${PORT}/api/recognize-food`,
  );
  console.log("--------------------------------");
});
