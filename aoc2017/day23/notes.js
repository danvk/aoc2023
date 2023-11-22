let h = 0;

// let b=109300
// let c=126300
let b = 93
let c = 1000

// 1000 iterations
for (; b <= c; b += 17) {
    let f = 1
    let d = 2
    do {
        let e = 2
        do {
            if (d * e == b) {
                f = 0
            }
            e += 1
        } while (e != b)
        d += 1
    } while (d != b);
    if (f == 0) {
        h += 1
    }
}

console.log(h);
