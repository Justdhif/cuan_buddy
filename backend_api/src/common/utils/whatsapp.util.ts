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

  // Standard fallback image URL (financial workspace)
  const finalImageUrl = imageUrl || 'https://picsum.photos/500/300.jpg';

  try {
    const params = new URLSearchParams();
    params.append('target', phone);
    params.append('message', messageText);
    params.append('url', finalImageUrl);

    const response = await fetch('https://api.fonnte.com/send', {
      method: 'POST',
      headers: {
        'Authorization': fonnteApiKey,
      },
      body: params,
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
