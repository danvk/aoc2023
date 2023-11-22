let h = 0;

// let b=109300
// let c=126300
let b = 93
let c = 1000

// 1000 iterations
for (; b <= c; b += 17) {
    let f = 1
    for (let d = 2; d < b; d++) {
        for (let e = 2; e < b; e++) {
            if (d * e == b) {
                f = 0
            }
        }
    }
    if (f == 0) {
        h += 1
    }
}

console.log(h);
