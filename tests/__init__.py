import unittest


def test_suite():
    loader = unittest.TestLoader()
    suite = loader.discover()
