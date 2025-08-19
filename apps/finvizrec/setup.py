from setuptools import setup

setup(
    name="finvizrec",
    version="0.1.0",
    py_modules=["finvizrec"],
    install_requires=[
        "finvizfinance>=0.9.4",
        "pandas>=1.0",
    ],
    entry_points={
        "console_scripts": [
            "finvizrec=finvizrec:main",
        ],
    },
)
