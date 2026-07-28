export interface SendWaOptions {
  phone: string;
  title: string;
  description: string;
  imageUrl?: string;
}

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

  const appVersion = process.env.CUAN_BUDDY_VERSION || '1.0.0';
  const appFooter = `CuanBuddy v${appVersion}`;

  // Bold title and double space for application footer
  const messageText = `*${title}*\n${description}\n\n${appFooter}`;

  // Clean phone number (remove spaces, +, -, etc.)
  let cleanPhone = phone.replace(/[^0-9]/g, '');
  if (cleanPhone.startsWith('0')) {
    cleanPhone = '62' + cleanPhone.slice(1);
  }

  try {
    const params = new URLSearchParams();
    params.append('target', cleanPhone);
    params.append('message', messageText);
    
    // Only send url if explicitly provided to prevent Fonnte media download errors
    if (imageUrl) {
      params.append('url', imageUrl);
    }

    const response = await fetch('https://api.fonnte.com/send', {
      method: 'POST',
      headers: {
        'Authorization': fonnteApiKey,
      },
      body: params,
    });

    const resData = await response.json();
    if (!response.ok || !resData.status) {
      return { success: false, reason: resData.reason || resData.detail || JSON.stringify(resData) };
    }

    return { success: true };
  } catch (error: any) {
    return { success: false, reason: error.message || error.toString() };
  }
}
