// k6 — ramping load designed to drive CPU up and trigger the HPA scale-out.
// Watch `kubectl get hpa -n <ns> -w` and the Grafana "HPA replicas" panel.
//
//   BASE_URL=http://localhost:3000 k6 run tests/k6/stress-hpa.js
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const FLAG_KEY = __ENV.FLAG_KEY || 'checkout-v2';

export const options = {
  scenarios: {
    ramp: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 }, // warm up
        { duration: '3m', target: 400 }, // push CPU past the 70% HPA target
        { duration: '3m', target: 400 }, // hold to let HPA stabilise replicas
        { duration: '2m', target: 0 }, // ramp down -> observe scale-in
      ],
    },
  },
};

export default function () {
  // Mix cached reads with an occasional list to add DB/compute pressure.
  const res = http.get(`${BASE_URL}/api/flags/${FLAG_KEY}`);
  check(res, { 'status is 200': (r) => r.status === 200 });
  if (Math.random() < 0.1) {
    http.get(`${BASE_URL}/api/flags?env=production`);
  }
}
