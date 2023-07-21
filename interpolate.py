from scipy import interpolate
import numpy as np
import argparse

def f(filename:str, x:float or list, k:int = 3):

    # read first and last column of tab separated text file
    x_pts, _, y_pts = np.loadtxt(filename, unpack=True)
    tck = interpolate.splrep(x_pts, y_pts, k=k) # k=3 is cubic spline interpolation
    return interpolate.splev(x, tck)

# make command line interface

def main():
    """
    Example: 
    
    filename = "results.txt"
    x = np.arange(0.1,0.70,0.01)
    print(f(filename, x))
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("filename", help="file to read", type=str)
    parser.add_argument("x", help="x value to interpolate", type=float)
    parser.add_argument("--k", "-k", default=3, help = "Degree of spline fit. 1 <= k <= 5", type=int)

    args = parser.parse_args()
    
    y = f(args.filename, args.x, args.k)

    print(f"{y:.4f}")

    return y

if __name__ == '__main__':
    main()