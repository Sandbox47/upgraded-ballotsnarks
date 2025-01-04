# Curve25519 in Circom
Curve 25519 is a montgomery elliptic curve defined (in its affine representation) by $y^2=x^3+486662x^2 + x$ over the prime field defined by the prime number $2^{255}-19$.

## The field $\mathbb{F}_{2^{255}-19}$
- $2^{255}-19$ is larger than the order of the prime field $p$ used in Circom. (https://docs.circom.io/circom-language/basic-operators/)
- Therefore, we need to split each field element of Curve25519 into multiple field elements in Circom. Here, we can represent each element $q$ as an array of $255$ bits or as a tuple of $3$ field element the addition of which equals $q$.
- To reduce the number of constraints, we choose the chucnked approach and base our implementation on the one provided in https://github.com/Electron-Labs/ed25519-circom/tree/main
- 

## The elliptic curve group law

### Affine vs. Projective

### xAdd and xDbl
For xAdd, we need to now $P, Q$ and $P\ominus Q$. Since we are usually computing this in the context of a scalar multiplication $[k]P$, we know $P\omis Q$ from previous computations.

### Montgomery ladder



Circom base field:
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617

BN254 Order of scalar field:
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
