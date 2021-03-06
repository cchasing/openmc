import os

import numpy as np
import pytest
import openmc.data
pytestmark = pytest.mark.skipif(
    'OPENMC_MULTIPOLE_LIBRARY' not in os.environ,
    reason='OPENMC_MULTIPOLE_LIBRARY environment variable must be set')


@pytest.fixture(scope='module')
def u235():
    directory = os.environ['OPENMC_MULTIPOLE_LIBRARY']
    filename = os.path.join(directory, '092235.h5')
    return openmc.data.WindowedMultipole.from_hdf5(filename)


@pytest.fixture(scope='module')
def b10():
    directory = os.environ['OPENMC_MULTIPOLE_LIBRARY']
    filename = os.path.join(directory, '005010.h5')
    return openmc.data.WindowedMultipole.from_hdf5(filename)


def test_evaluate(u235):
    """Test the cross section evaluation of a library."""
    energies = [1e-3, 1.0, 10.0, 50.]
    scattering, absorption, fission = u235(energies, 0.0)
    assert (scattering[1], absorption[1], fission[1]) == \
           pytest.approx((13.09, 77.56, 67.36), rel=1e-3)
    scattering, absorption, fission = u235(energies, 300.0)
    assert (scattering[2], absorption[2], fission[2]) == \
           pytest.approx((11.24, 21.26, 15.50), rel=1e-3)


def test_evaluate_none_poles(b10):
    """Test a library with no poles, i.e., purely polynomials."""
    energies = [1e-3, 1.0, 10.0, 1e3, 1e5]
    scattering, absorption, fission = b10(energies, 0.0)
    assert (scattering[0], absorption[0], fission[0]) == \
           pytest.approx((2.201, 19330., 0.), rel=1e-3)
    scattering, absorption, fission = b10(energies, 300.0)
    assert (scattering[-1], absorption[-1], fission[-1]) == \
           pytest.approx((2.878, 1.982, 0.), rel=1e-3)


def test_export_to_hdf5(tmpdir, u235):
    filename = str(tmpdir.join('092235.h5'))
    u235.export_to_hdf5(filename)
    assert os.path.exists(filename)
