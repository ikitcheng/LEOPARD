#!/bin/bash
# CONSTANTS
filename_results="results.txt"
filename_dsolve_log="dsolve.log"
omega_i0=0.0232
krange=$(seq 0.1 0.05 0.8)
interp_degree=3 # cubic (interpolation routine requires nPts > interp_degree)

# New values for wavenumber
for kstart in $krange
do
    kend=$kstart

    # Check if the `results.txt` file has non-zero size
    if [ -s "$filename_results" ]; then

        # Count number of lines in results.txt (need at least two for interpolation)
        n_results=$(wc -l < $filename_results)

        if [ $n_results -lt $(($interp_degree+1)) ]; then
            # get the last omega_i value
            echo "Reading the last omega_i"
            omega_i=$(tail -n 1 "$filename_results" | cut -f 3)
        else
            # Use an interpolation function to estimate the next omega_i
            echo "Interpolating omega_i..."
            omega_i=$(python3 interpolate.py -k $interp_degree "results.txt" $kstart)
        fi
    else
        omega_i=$omega_i0
    fi

    echo "Preparing INPUT..."
    echo "kstart: $kstart, kend: $kend, omega_i: $omega_i"

    # Use sed to modify the values in the input.dat file
    sed -i "s/kstart =0.*/kstart =$kstart/" input.dat
    sed -i "s/kend =0.*/kend =$kend/" input.dat
    sed -i "s/omega_i =0.*/omega_i =$omega_i/" input.dat

    # Run LEOPARD
    echo "Running LEOPARD..."
    output=$(./dsolve)

    # Store terminal output to $output, and save in `dsolve.log`` file. 
    echo "$output">>$filename_dsolve_log

    # Extract k, omega and gamma values
    k=$(echo "$output" | grep -o -P '(?<=k=)\s*\S+' | awk '{print $1}')
    omega=$(echo "$output" | grep -o -P '(?<=omega:)\s+ -?[0-9.]*E[+-][0-9]*' | awk '{print $1}')
    gamma=$(echo "$output" | grep -o -P '(?<=gamma:)\s+ -?[0-9.]*E[+-][0-9]*' | awk '{print $1}')

    # Print the extracted values
    echo "Saving results..."
    echo "k= $k,omega= $omega,gamma= $gamma"

    # Append the k, omega, and gamma values to `results.txt` in a single row with tab separation
    echo -e "$k\t$omega\t$gamma" >> $filename_results
    break
done

# End of script 
echo "Finished."
exit