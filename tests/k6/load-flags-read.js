// k6 — steady-state read load on the cache-hot path GET /api/flags/{key}.
// Validates SLOs (P95 <= 300ms, error rate < 0.1%) under normal traffic.
//
//   BASE_URL=http://localhost:3000 FLAG_KEY=checkout-v2 k6 run tests/k6/load-flags-read.js
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const FLAG_KEY = __ENV.FLAG_KEY || 'checkout-v2';

export const options = {
  scenarios: {
    steady: {
      executor: 'constant-arrival-rate',
      rate: 200, // requests per second
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<300'], // SLO: P95 <= 300ms
    http_req_failed: ['rate<0.001'], // SLO: error rate < 0.1%
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/api/flags/${FLAG_KEY}`);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'has body': (r) => r.body && r.body.length > 0,
  });
  sleep(0.1);
}
