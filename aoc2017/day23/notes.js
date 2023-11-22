let h = 0;

let b=109300
let c=126300
// let b = 93
// let c = 1000

function isComposite(b) {
    for (let d = 2; d <= Math.sqrt(b); d++) {
        if (b % d == 0) {
            return true;
        }
    }
    return false;
}

// 1000 iterations
for (; b <= c; b += 17) {
    if (isComposite(b)) {
        h += 1
    }
}

console.log(h);
