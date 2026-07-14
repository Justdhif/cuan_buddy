export interface SendWaOptions {
  phone: string;
  title: string;
  description: string;
  imageUrl?: string;
}

/**
 * Sends a WhatsApp message via Fonnte API with a standardized format:
 * - Image (using default fallback if none provided)
 * - Bold Title
 * - Description
 * - Footer with App Name & Version
 */
export async function sendWhatsAppMessage({
  phone,
  title,
  description,
  imageUrl,
}: SendWaOptions): Promise<{ success: boolean; reason?: string }> {
  const fonnteApiKey = process.env.FONNTE_API_KEY;
  if (!fonnteApiKey) {
    return { success: false, reason: 'FONNTE_API_KEY is not defined in environment.' };
  }

  // Application Name + Version
  const appVersion = process.env.CUAN_BUDDY_VERSION || '1.0.0';
  const appFooter = `CuanBuddy v${appVersion}`;

  // Bold title and double space for application footer
  const messageText = `*${title}*\n${description}\n\n${appFooter}`;

  // Standard fallback image URL
  const finalImageUrl = imageUrl || 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=500';

  try {
    const response = await fetch('https://api.fonnte.com/send', {
      method: 'POST',
      headers: {
        'Authorization': fonnteApiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        target: phone,
        message: messageText,
        url: finalImageUrl,
      }),
    });

    const resData = await response.json();
    if (!response.ok || !resData.status) {
      return { success: false, reason: resData.reason || JSON.stringify(resData) };
    }

    return { success: true };
  } catch (error) {
    return { success: false, reason: error.message || error.toString() };
  }
}
