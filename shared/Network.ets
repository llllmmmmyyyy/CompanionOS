import { http } from '@kit.NetworkKit';

export async function backendRequest(url: string, method: string = 'GET', data: string = '', responseLimit: number = 32768): Promise<string> {
  const request = http.createHttp();
  try {
    const response = await request.request(url, {
      method: method === 'POST' ? http.RequestMethod.POST : http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' }, extraData: data,
      expectDataType: http.HttpDataType.STRING, connectTimeout: 3000, readTimeout: 5000,
      maxLimit: Math.min(262144, Math.max(32768, responseLimit)), usingCache: false
    });
    if (response.responseCode < 200 || response.responseCode >= 300 || typeof response.result !== 'string') {
      throw new Error(`HTTP ${response.responseCode}: relay request failed`);
    }
    return response.result;
  } catch (error) {
    const failure = error as Error;
    console.error(`[CompanionRelay] ${method} ${url}: ${failure.message}`);
    throw failure;
  } finally { request.destroy(); }
}
