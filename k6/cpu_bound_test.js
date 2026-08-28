import http from 'k6/http';
import {check} from 'k6';

export const options = {
    thresholds: {
        http_req_failed: ['rate<0.01'],
    },
};

export default function () {
    const iterations = 10000;
    const res = http.get(`http://localhost:8080/benchmark/cpu-bound?iterations=${iterations}`, {
        tags: {name: 'CpuBenchmark'},
    });

    check(res, {
        'status is 200': (r) => r.status === 200,
        'hash is valid': (r) => {
            const body = r.json();
            return body && typeof body.hash === 'string' && body.hash.length === 64;
        },
    });
}
