interface HttpRequestOptions {
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
    headers?: Record<string, string>;
    body?: string;
    timeout?: number;
}
interface HttpResponse<T = any> {
    data: T;
    status: number;
    statusText: string;
    headers: Record<string, string>;
}
export declare class HttpClient {
    private defaultTimeout;
    request<T = any>(url: string, options?: HttpRequestOptions): Promise<HttpResponse<T>>;
    get<T = any>(url: string, headers?: Record<string, string>): Promise<HttpResponse<T>>;
    post<T = any>(url: string, data?: any, headers?: Record<string, string>): Promise<HttpResponse<T>>;
}
export declare const httpClient: HttpClient;
export {};
//# sourceMappingURL=http-client.d.ts.map