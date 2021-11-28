// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.4;

library Math {
    // babylonian method
    // https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
    function sqrt(uint y) internal pure returns (uint) {
        if (y > 3) {
            uint z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
            return z;
        } else if (y != 0) {
            return 1;
        }
        return 0;
    }
}
