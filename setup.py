"""Installation file for the ansys-api-discovery package"""

import os
from datetime import datetime

import setuptools

from ansys.tools.protoc_helper import CMDCLASS_OVERRIDE

# Get the long description from the README file
HERE = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(HERE, "README.md"), encoding="utf-8") as f:
    long_description = f.read()

product = "discovery"
library = ""
package_info = ["ansys", "api", product, library,"v0"]
with open(os.path.join(HERE, "ansys", "api", product, library, "VERSION"), encoding="utf-8") as f:
    version = f.read().strip()

package_name = "ansys-api-discovery"
dot_package_name = '.'.join(filter(None, package_info))

description = f"Autogenerated python gRPC interface package for {package_name}, built on {datetime.now().strftime('%H:%M:%S on %d %B %Y')}"

if __name__ == "__main__":
    setuptools.setup(
        name=package_name,
        version=version,
        author="ANSYS, Inc.",
        author_email='support@ansys.com',
        description=description,
        long_description=long_description,
        long_description_content_type='text/markdown',
        url=f"https://github.com/ansys/{package_name}",
        license="MIT",
        python_requires=">=3.7",
        install_requires=["grpcio~=1.47", "protobuf~=3.19"],
        packages=setuptools.find_namespace_packages(".", include=("ansys.*",)),
        package_data={
            "": ["*.proto", "*.pyi", "py.typed", "VERSION"],
        },
        entry_points={
            "ansys.tools.protoc_helper.proto_provider": [
                f"{dot_package_name}={dot_package_name}"
            ],
        },
        cmdclass=CMDCLASS_OVERRIDE
    )
