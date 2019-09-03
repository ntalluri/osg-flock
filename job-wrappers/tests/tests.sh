#!/bin/bash

function run_test {
    
    # cleanup
    rm -f .singularity*
    rm -f test.err test.out

    echo "Running" "$@"
    "$@" >test.out 2>test.err
    if [ $? -eq 0 ]; then
        echo "OK"
        rm -f test.err test.out
        return 0
    else
        cat test.err test.out
        echo "ERROR"
        exit 1
    fi
}

function test_non_singularity {
    export _CONDOR_MACHINE_AD=$PWD/.machine_ad.non-singularity
    if ! ($PWD/user-job-wrapper.sh ls); then
        echo "ERROR: job exited non-zero"
        return 1
    fi
    if [ -e .singularity.startup-ok ]; then
        echo "ERROR: .singularity.startup-ok exists - this is unexpected"
        return 1 
    fi
    return 0
}

function test_non_singularity_fail {
    export _CONDOR_MACHINE_AD=$PWD/.machine_ad.non-singularity
    if ($PWD/user-job-wrapper.sh false); then
        echo "ERROR: job exited zero - we expected failure"
        return 1
    fi
    return 0
}

function test_singularity {
    export _CONDOR_MACHINE_AD=$PWD/.machine_ad.singularity
    if ! ($PWD/user-job-wrapper.sh ls); then
        echo "ERROR: job exited non-zero"
        return 1
    fi
    if [ ! -e .singularity.startup-ok ]; then
        echo "ERROR: .singularity.startup-ok is missing - did the job run in Singularity?"
        return 1 
    fi
    return 0
}

function test_singularity_fail_1 {
    # missing image
    export _CONDOR_MACHINE_AD=$PWD/.machine_ad.singularity-fail
    $PWD/user-job-wrapper.sh ls
    if [ -e .singularity.startup-ok ]; then
        echo "ERROR: .singularity.startup-ok exists - this is unexpected"
        return 1 
    fi
    return 0
}

function test_singularity_fail_2 {
    # test with good image, bad Singularity binary
    export _CONDOR_MACHINE_AD=$PWD/.machine_ad.singularity-bad-detection
    export _CONDOR_WRAPPER_ERROR_FILE=$PWD/.condor_wrapper_error_file
    rm -f $_CONDOR_WRAPPER_ERROR_FILE
    if ($PWD/user-job-wrapper.sh true); then
        echo "ERROR: job exited zero, we expected non-zero"
        return 1
    fi
    if [ -e .singularity.startup-ok ]; then
        echo "ERROR: .singularity.startup-ok exists - this is unexpected"
        return 1 
    fi
    if [ ! -e $_CONDOR_WRAPPER_ERROR_FILE ]; then
        echo "ERROR: \$_CONDOR_WRAPPER_ERROR_FILE was not created"
        return 1 
    fi
    rm -f $_CONDOR_WRAPPER_ERROR_FILE
    return 0
}

function test_singularity_fail_3 {
    # test with good image, bad user job
    export _CONDOR_MACHINE_AD=$PWD/.machine_ad.singularity
    if ($PWD/user-job-wrapper.sh false); then
        echo "ERROR: job exited zero, we expected non-zero"
        return 1
    fi
    if [ ! -e .singularity.startup-ok ]; then
        echo "ERROR: .singularity.startup-ok is missing - this is unexpected"
        return 1 
    fi
    return 0
}

# we need a copy as it will be used inside containers
cp ../user-job-wrapper.sh .

export GWMS_DEBUG=1

# run the tests
run_test test_non_singularity
run_test test_non_singularity_fail
run_test test_singularity
run_test test_singularity_fail_1
run_test test_singularity_fail_2
run_test test_singularity_fail_3

# cleanup
rm -f .singularity.startup-ok .user-job-wrapper.sh user-job-wrapper.sh

