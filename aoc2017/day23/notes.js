let h = 0;

// 1000 iterations
for (let b=109300; b <= 126300; b += 17) {
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
