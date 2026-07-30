export interface SendWaOptions {
  phone: string;
  title: string;
  description: string;
}

export async function sendWhatsAppMessage({
  phone,
  title,
  description,
}: SendWaOptions): Promise<{ success: boolean; reason?: string }> {
  const phoneNumberId = process.env.WA_PHONE_NUMBER_ID;
  const accessToken = process.env.WA_CLOUD_API_ACCESS_TOKEN;

  if (!phoneNumberId || !accessToken) {
    return { success: false, reason: 'WhatsApp Cloud API credentials (WA_PHONE_NUMBER_ID / WA_CLOUD_API_ACCESS_TOKEN) are not defined in environment.' };
  }

  const appVersion = process.env.CUAN_BUDDY_VERSION || '1.0.0';
  const appFooter = `CuanBuddy v${appVersion}`;

  // Formatted message text
  const messageText = `*${title}*\n${description}\n\n${appFooter}`;

  // Clean phone number to E.164 (e.g. 6282113285557)
  let cleanPhone = phone.replace(/[^0-9]/g, '');
  if (cleanPhone.startsWith('0')) {
    cleanPhone = '62' + cleanPhone.slice(1);
  }

  try {
    const url = `https://graph.facebook.com/v19.0/${phoneNumberId}/messages`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        recipient_type: 'individual',
        to: cleanPhone,
        type: 'text',
        text: { preview_url: false, body: messageText },
      }),
    });

    const resData = await response.json();

    if (!response.ok || resData.error) {
      return { success: false, reason: resData.error?.message || JSON.stringify(resData) };
    }

    return { success: true };
  } catch (error: any) {
    return { success: false, reason: error.message || error.toString() };
  }
}

