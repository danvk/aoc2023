let h = 0;

// let b=109300
// let c=126300
let b = 93
let c = 1000

function check(b) {
    for (let d = 2; d < b; d++) {
        for (let e = 2; e < b; e++) {
            if (d * e == b) {
                return true;
            }
        }
    }
    return false;
}

// 1000 iterations
for (; b <= c; b += 17) {
    if (check(b)) {
        h += 1
    }
}

console.log(h);
