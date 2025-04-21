import http from 'k6/http';

export default function () {
    http.get('http://localhost:8080/demo/sum?value1=3&value2=5');
}
