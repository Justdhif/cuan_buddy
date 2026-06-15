export function formatCurrency(amount: string | number): string {
  const numericAmount = Number(amount);
  if (isNaN(numericAmount)) return 'Rp 0';
  
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(numericAmount);
}

export function formatDate(date: Date | string): string {
  if (!date) return '-';
  const d = new Date(date);
  
  return new Intl.DateTimeFormat('id-ID', {
    dateStyle: 'long',
    timeStyle: 'short',
  }).format(d).replace('pukul', '').trim();
}

export function formatPaginatedResponse(data: any[], total: number, page: number, limit: number) {
  return {
    data,
    meta: {
      page: Number(page),
      limit: Number(limit),
      total: Number(total),
      totalPages: Math.ceil(Number(total) / Number(limit))
    }
  };
}
