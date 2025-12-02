module Utility::Write

import IO;
import Conf;

void writeToClonesJson(str content) {
    writeFile(clonesJson, content, false);
}