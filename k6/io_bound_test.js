import http from 'k6/http';
import {check} from 'k6';

export const options = {
    thresholds: {
        http_req_failed: ['rate<0.01'],
    },
};

export default function () {
    const val1 = Math.floor(Math.random() * 1000) + 1;
    const val2 = Math.floor(Math.random() * 1000) + 1;
    const expectedSum = val1 + val2;

    const res = http.get(`http://localhost:8080/benchmark/io-bound?value1=${val1}&value2=${val2}&delay=100`, {
        tags: {name: 'IoBenchmark'},
    });

    check(res, {
        'status is 200': (r) => r.status === 200,
        'result matches sum': (r) => {
            const body = r.json();
            return body && body.result === expectedSum;
        },
    });
}
