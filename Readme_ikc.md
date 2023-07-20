# Quickstart
- Compiler: compiler version gcc 6.1.
- Check installed compiler versions: `dpkg --list | grep compiler`
- Run `make`
- Execute `./dsolve`

# Summary of LEOPARD
- 'Linear Electromagnetic Oscillations in Plasmas with Arbitrary Rotationally-symmetric Distributions'
- Derive frequencies and growth rates of EM waves
- Arbitrary propagation angle
- Arbitrary number of species
- Computes fully-kinetic dielectric tensor for bi-Maxwellian or arbitrary gyrotropic velocity distributions
- The velocity distribution is inputed as a data set sampled on the 2d (vpara,vperp) velocity space: 
1) from parametric model distribution, 
2) from kinetic simulation, 
3) spacecraft measurement
- column 1 = v_para, column 2 = v_perp, column 3 = F(vpara,vperp).
- equdistant grid
- For each v_para (low to high), F is scanned for all v_perp, before proceeding with the next v_para
- `distribution/print_bimax.py` produces a bi-maxwellian
- Velocities normalized wrt Alfven velocity of the first species
- Distribution normalized wrt Alfven velocity and species densiy such that: \int F(v_para,v_perp)*v_perp dv_perp dv_para = 1.0.
- When `mode_in=1` in `input.dat`, the code then reads the distribution from the file `distribution/distributionX.dat` where 'X' is the index ('1', '2', '3', ...)  of the corresponding particle species. The numbering is according to all included species with arbitrary velocity distributions `mode_in=1`.

# How it works?
- Loop over wavenumbers
	-> iterative root finding algorithm with `muller()`
- 'input.dat'
	- Wavenumber interval
	- initial frequency guesses for the first three wavenumbers
- `muller()` iterates and finds complex root
	- for every iteration, the determinant of the dispersion tensor has to be evaluated 
	- The determinant requires computing the dielectric tensor components, done by `disp_det()`; sum over the Bessel index `n`
		- bi-maxwellian distribution
			- `mode='0'` & beta parameters => dielectric tensor can be computed 
			- `Z_func` evaluates the plasma dispersion function
		- arbitrary distribution
			- `mode='0'`
			- data is interpolated with cubic splines which allows a piecewise-analytic solution of the required velocity integrations

- Output all roots (`k`, `omega_r`, `omega_i`) in `omega.dat`

# Input parameters

## `&wavenumber`
`kstart` - The lower bound of the wavenumber interval
`kend`   - The upper bound of the wavenumber interval
`nk`     - Number of points to evaluate the dispersion relation within the chosen wavenumber interval.

Note:
Normalization: All wavenumbers are given in units of 'inertial length', d, of the first particle species. i.e. `k_Leopard = kd = kc/omega_pi = kv_A/\Omega_i`


## `&initial_guess`
`omega_r`     - The initial guess for the real frequency from which the Muller method starts to find a root, `omega(k)`, of the dispersion relation at the wavenumber `k(1)=kstart`.

`omega_i`     - The initial guess for the growth or damping rate from which the Muller method starts to find a root, `omega(k)`, of the dispersion relation at the wavenumber `k(1)=kstart`.

`increment_r` - The frequency value by which the previously found root, `omega(k)`, is incremented to provide the starting value for the next Muller iteration at the subsequent wavenumber, `k(i+1)=k(i)+dk`.

`increment_i` - The growth rate value by which the previously found root, `omega(k)`, is incremented to provide the starting value for the next Muller iteration at the subsequent wavenumber, `k(i+1)=k(i)+dk`.

Note: 
Need proper initial guess to converge to the root corresponding to the dispersion branch of interest.
Normalization: Both frequencies and growth rates are always given in units of the gyro frequency of the first particle species.


## `&setup`
`Nspecies` - The number of particle species the user wants to include.
`theta`    - The propagation angle of the waves, i.e. the angle between the wave vector k and the background magnetic field (which is aligned with the z-axis in the chosen coordinate system).
`delta`    - Ratio of gyro frequency and plasma frequency of the first particle species.

Note:
- The parallel and perpendicular wavenumbers are given as `k_para=k*cos(theta)` and `k_perp=k*sin(theta)`.
- `delta = B \sqrt{\epsilon_0/(nm)} = v_A/c` gives a measure for the magnetization of the plasma. Low `delta` corresponds to weak, high `delta` corresponds to strong magnetization. i.e. `delta` is a measure of magnetic field strength, since a large magnetic field leads to high gyrofrequency.

## `&accuracy`
`rf_error`    - The 'root finding error' gives the exit-condition for the Muller iteration. An error of 1.0d-2 or 1.0d-3 generally gives good results. But - of course - the choice depends on the accuracy requested by the user.

`eps_error`   - The 'epsilon error' gives the exit condition for the sum over the Bessel index n. Once the relative contribution of the computed dielectric tensor components for a given n gets smaller than the given `eps_error`, the code exits the loop.

Note:
If a solution seems fishy, play with these parameters and check whether the solution is numerically converged.
Choose the `rf_error` to be not too demanding, otherwise LEOPARD may run into convergence problems.


## `&species`
For each species, include the below parameters
`mode_in`    - Choose '0' for a bi-Maxwellian plasma or '1' for a plasma with arbitrary gyrotropic velocity distribution

`q_in`       - Charge of the particles in units of the charge of the first particle species.

`mu_in`      - Inverse mass of the particles in units of the inverse mass of the first particle species.

`dens_in`	 - Density of the particles in units of the density of the first particle species

`drift_in`   - This introduces a drift velocity to the bi-Maxwellian distribution (mode '0' only). The drift is normalized with respect to the Alfvén velocity.

`beta_para_in` - Beta parameter parallel to the background magnetic field (mode '0' only).

`beta_perp_in` - Beta parameter perpendicular to the background magnetic field (mode '0' only).


Note:
- `beta_para_in = 3*beta_in/(1+2a)` where `a=beta_perp_in/beta_para_in` is the anisotropy and `beta_in` is the total plasma beta for this species.

- `beta_perp_in = 3*a*beta_in/(1+2a)` where `a=beta_perp_in/beta_para_in` is the anisotropy and `beta_in` is the total plasma beta for this species.

- For electron plasma beta, if the ratio `T_e/T_para_p` is given (e.g. in Gary 1992), then `beta_e = T_e/T_para_p*beta_para_p`. Assume electrons are isotropic, this means `beta_para_in = beta_perp_in`

- If you need more than the two default particle species, just add additional parameter blocks below the two default `&species` blocks. Make sure to modify `Nspecies` accordingly. The choice, which particle species is declared in the first &species block, is of major importance since the normalization of all output data depends on this choice. E.g., if you choose protons to be the first particle species, then all frequencies and growth rates will be given in units of the proton gyrofrequency and the wavenumbers will be in units of the proton inertial length.

- When including particle species with arbitrary velocity distribution, the size of the provided velocity grid will significantly affect the performance of LEOPARD. Good accuracy at sufficiently fast run times was found for distribution grids with 200 points in v_para and 100 points in v_perp - but in general the performance is highly dependent on the detailed velocity space structure of the distribution and the considered dispersion branch.

## Tips
* You may need to adjust the wavenumber and growth rate ranges bit by bit. E.g. in the range k = 0.4 to 0.9, we expect the growth rate to be around 0.01. When we get the following error `Program received signal SIGFPE: Floating-point exception - erroneous arithmetic operation.` it means the program didn't converge on any solution. 
* I found that adjusting `omega_i` by increments of 0.010 and setting `increment_i= 0.001` helped put it on the right branch, which is crucial to finding subsequent solutions. The more significant figures you can provide for `omega_i`, the better. 
* Also, making `increment_i` smaller helps. 
* Doing one `k` value at a time seems to be easier to get convergence. 