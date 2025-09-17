"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.httpClient = exports.HttpClient = void 0;
class HttpClient {
    constructor() {
        this.defaultTimeout = 30000; // 30 seconds
    }
    async request(url, options = {}) {
        const { method = 'GET', headers = {}, body, timeout = this.defaultTimeout } = options;
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);
        try {
            const response = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    ...headers
                },
                body,
                signal: controller.signal
            });
            clearTimeout(timeoutId);
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            const data = await response.json();
            const responseHeaders = {};
            response.headers.forEach((value, key) => {
                responseHeaders[key] = value;
            });
            return {
                data,
                status: response.status,
                statusText: response.statusText,
                headers: responseHeaders
            };
        }
        catch (error) {
            clearTimeout(timeoutId);
            if (error instanceof Error && error.name === 'AbortError') {
                throw new Error(`Request timeout after ${timeout}ms`);
            }
            throw error;
        }
    }
    async get(url, headers) {
        return this.request(url, { method: 'GET', headers });
    }
    async post(url, data, headers) {
        return this.request(url, {
            method: 'POST',
            headers,
            body: data ? JSON.stringify(data) : undefined
        });
    }
}
exports.HttpClient = HttpClient;
exports.httpClient = new HttpClient();
//# sourceMappingURL=http-client.js.map