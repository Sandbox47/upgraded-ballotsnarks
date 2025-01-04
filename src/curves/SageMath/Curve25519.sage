# ================================================================================
## MONTGOMERY:

# Curve equation: By^2=x^3+Ax^2+x mod p
# Prameters for Curve 25519:
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
Zp = GF(p)
A = Zp(126932)
B = Zp(1)

# ================================================================================
## SHORT WEIERSTRASS:

# Curve equation: v^2=t^3+at+b
# Parameters (calculated from montgomery equation) (according to MoonMathManual, 
# 5.2 Montgomery curves):
a = (Zp(3)-A**2)/(Zp(3)*B**2)
b = (Zp(2)*A**3-Zp(9)*A)/(Zp(27)*B**3)
# Define the elliptic curve
E = EllipticCurve([a, b])
# print(a)
# print(b)

# ================================================================================
## TRANSFORMATIONS:

# Montgomery to Weierstrass: M_{A, B} -> E_{a,b}
def montgomeryToShortWeierstrass(x, y):
    """
    Map a point (x, y) from Montgomery form to Weierstrass form.
    """
    return Zp(x)/B + A/(Zp(3)*B), Zp(y)/B

def computeShortWeierstrassToMontgomeryParameters():
    # Weierstrass to Montgomery: E_{a,b} -> M_{A, B}
    # Define the cubic equation z^3 + az + b = 0 and find roots
    R.<z> = PolynomialRing(Zp)
    cubic = z^3 + a*z + b
    roots = cubic.roots()

    # Ensure the cubic equation has at least one root
    if not roots:
        raise ValueError("The cubic equation z^3 + az + b = 0 has no roots in F.")

    # Pick the first root α (or choose based on your application)
    alpha = roots[0][0]

    # Check if 3α^2 + a is a quadratic residue
    quad_residue = 3*alpha^2 + a
    if not quad_residue.is_square():
        raise ValueError("3α^2 + a is not a quadratic residue in F.")

    # Compute s = 1 / sqrt(3α^2 + a)
    s = 1 / quad_residue.sqrt()
    return alpha, s

alpha, s = computeShortWeierstrassToMontgomeryParameters()

def shortWeierstrassToMontgomery(t, v):
    """
    Map a point (t, v) from Weierstrass form to Montgomery form.
    """
    x = s * (t - alpha)
    y = s * v
    return x, y

# ================================================================================
# TEST TRANSFORMATION:

def testTransformation():
    point_SW = E.random_point() # Point in Short Weierstrass form
    t = point_SW[0]  # x-coordinate
    v = point_SW[1]  # y-coordinate
    x, y = shortWeierstrassToMontgomery(t, v)
    print(f"Point on Weierstrass curve: (t, v) = ({t}, {v})")
    print(f"Point on Montgomery curve: (x, y) = ({x}, {y})")

    t_new, v_new = montgomeryToShortWeierstrass(x,y)
    print(f"Point (x, y) transformed back to Weierstrass curve: (t_new, v_new) = ({t_new}, {v_new})")

    if t_new == t and v_new == v:
        print("Transformation worked")
    else:
        print("Transformation failed")

# ================================================================================
# TEST ADDITION:
# def generateRandomPoints():
point_SW_1 = E.random_point() # Point in Short Weierstrass form
t_1 = point_SW_1[0]  # x-coordinate
v_1 = point_SW_1[1]  # y-coordinate
point_SW_2 = point_SW_1
while point_SW_1 == point_SW_2:
    point_SW_2 = E.random_point() # Point in Short Weierstrass form
t_2 = point_SW_2[0]  # x-coordinate
v_2 = point_SW_2[1]  # y-coordinate

x_1, y_1 = shortWeierstrassToMontgomery(t_1, v_1)
x_2, y_2 = shortWeierstrassToMontgomery(t_2, v_2)

print("Points on Weierstrass curve:")
print(f"(t_1, v_1) = ({t_1}, {v_1})")
print(f"(t_2, v_2) = ({t_2}, {v_2})")

print("Points on Montgomery curve:")
print(f"(x_1, y_1) = ({x_1}, {y_1})")
print(f"(x_2, y_2) = ({x_2}, {y_2})")

# Test chord rule:
def testAddChordRule():
    point_SW_add = point_SW_1 + point_SW_2
    t_add, v_add = point_SW_add[0], point_SW_add[1]
    x_add, y_add = shortWeierstrassToMontgomery(t_add, v_add)

    print("Points to add (montgomery):")
    print(f"(x_1, y_1) = ({x_1}, {y_1})")
    print(f"(x_2, y_2) = ({x_2}, {y_2})")

    print("Result (montgomery):")
    print(f"(x_add, y_add) = ({x_add}, {y_add})")


# Test tangent rule:
def testAddTangentRule():
    point_SW_add = point_SW_1 + point_SW_1
    t_add, v_add = point_SW_add[0], point_SW_add[1]
    x_add, y_add = shortWeierstrassToMontgomery(t_add, v_add)

    print("Point to add to itself (montgomery):")
    print(f"(x_1, y_1) = ({x_1}, {y_1})")

    print("Result (montgomery):")
    print(f"(x_add, y_add) = ({x_add}, {y_add})")

# Test add point with negated y coord:
def testAddNegation():
    point_SW_1_neg = -point_SW_1
    t_neg, v_neg = point_SW_1_neg[0], point_SW_1_neg[1]
    x_neg, y_neg = shortWeierstrassToMontgomery(t_neg, v_neg)

    point_SW_add = point_SW_1 + point_SW_1_neg
    t_add, v_add = point_SW_add[0], point_SW_add[1]
    x_add, y_add = shortWeierstrassToMontgomery(t_add, v_add)

    print("Point and its negation (montgomery):")
    print(f"(x_1, y_1) = ({x_1}, {y_1})")
    print(f"(x_neg, y_neg) = ({x_neg}, {y_neg})")

    print("Result of the addition (montgomery):")
    print(f"(x_add, y_add) = ({x_add}, {y_add})")

def testScalarMul():
    m = 42
    point_SW_mul = m * point_SW_1
    t_mul, v_mul = point_SW_mul[0], point_SW_mul[1]
    x_mul, y_mul = shortWeierstrassToMontgomery(t_mul, v_mul)

    print(f"Point to multiply with m = {m}:")
    print(f"(x_1, y_1) = ({x_1}, {y_1})")

    print("Result (montgomery):")
    print(f"(x_mul, y_mul) = ({x_mul}, {y_mul})")

# testAddChordRule()
testScalarMul()