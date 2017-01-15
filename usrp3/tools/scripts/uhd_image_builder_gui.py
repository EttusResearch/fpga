#!/usr/bin/env python
"""
Copyright 2016 Ettus Research LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

"""
uhd_image_builder GUI
"""
import sip
sip.setapi('QVariant', 2)
import os
import subprocess
import uhd_image_builder
import sys
import re
from PyQt4.QtCore import *
from PyQt4.QtGui import *
import xml.etree.ElementTree as ET

class MainWindow(QWidget):
    """
    UHD_IMAGE_BUILDER
    """
    def __init__(self):
        super(MainWindow, self).__init__()
        self.initGUI()

    def initGUI(self):
        ettusSources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'lib',\
            'rfnoc', 'Makefile.srcs')

        ##################################################
        # Initial Values
        ##################################################
        self.target = 'x300'
        self.device = 'x310'
        self.buildTarget = 'X310_RFNOC_HG'
        self.max_allowed_blocks = 10

        ##################################################
        # Buttons
        ##################################################
        ootBtn = QPushButton('Add OOT Blocks', self)
        ootBtn.setToolTip('Add your custom Out-of-tree blocks')
        ootBtn.move(80, 420)
        fromGRCBtn = QPushButton('Import from GRC', self)
        fromGRCBtn.move(340, 420)
        show_file_btn = QPushButton('Show instantiation File', self)
        show_file_btn.move(540, 420)
        AddBtn = QPushButton('>>', self)
        AddBtn.move(550, 100)
        AddBtn.setFixedSize(150, 50)
        RemBtn = QPushButton('<<', self)
        RemBtn.move(550, 220)
        RemBtn.setFixedSize(150, 50)
        genBitBtn = QPushButton('Generate .bit file', self)
        genBitBtn.move(775, 420)

        ##################################################
        # Checkbox
        ##################################################
        self.fillWithFifos = QCheckBox('Fill with FIFOs', self)
        self.fillWithFifos.move(560, 300)
        self.vivGui = QCheckBox('Open Vivado GUI', self)
        self.vivGui.move(560, 320)
        self.cleanall = QCheckBox('Clean IP', self)
        self.cleanall.move(560, 340)

        ##################################################
        # Connection of the buttons with their signals
        ##################################################
        ootBtn.clicked.connect(self.fileDiag)
        fromGRCBtn.clicked.connect(self.fileGRCDiag)
        show_file_btn.clicked.connect(self.showFile)
        AddBtn.clicked.connect(self.addToDesign)
        RemBtn.clicked.connect(self.removeFromDesign)
        genBitBtn.clicked.connect(self.genBit)

        ##################################################
        # Panels - QTreeModels
        ##################################################
        ### Far-left Panel: Build targets
        self.targets = QTreeView(self)
        self.targets.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.modelTargets= QStandardItemModel(self)
        self.modelTargets.setHorizontalHeaderItem(0, QStandardItem("Select build target"))
        self.targets.setModel(self.modelTargets)
        self.populateTargets('x300')
        self.populateTargets('e300')
        self.targets.setCurrentIndex(self.modelTargets.index(0, 0))
        self.targets.show()
        self.targets.move(20, 10)
        self.targets.setFixedSize(250,400)

        ### Central Panel: Available blocks
        ### Create tree to categorize Ettus Block and OOT Blocks in different lists
        self.blocksAvailable = QTreeView(self)
        self.blocksAvailable.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.blocksAvailable.setContextMenuPolicy(Qt.CustomContextMenu)
        EttusBlocks = QStandardItem("Ettus-provided Blocks")
        self.populateList(EttusBlocks,ettusSources)

        ootSources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
            'x300', 'Makefile.srcs')
        self.OOT = QStandardItem("OOT Blocks for X300 devices")
        self.populateList(self.OOT,ootSources)
        self.modelBlocksAvailable = QStandardItemModel(self)
        self.modelBlocksAvailable.appendRow(EttusBlocks)
        self.modelBlocksAvailable.appendRow(self.OOT)
        self.modelBlocksAvailable.setHorizontalHeaderItem(0, QStandardItem("List of blocks available"))
        self.blocksAvailable.setModel(self.modelBlocksAvailable)
        self.blocksAvailable.move(290,10)
        self.blocksAvailable.setFixedSize(250,400)

        self.targets.connect(self.targets.selectionModel(),
                SIGNAL('selectionChanged(QItemSelection, QItemSelection)'),
                self.ootlist) #check when the selection of this changes

        ### Far-right Panel: Blocks in current design
        self.blocksInDesign = QTreeView(self)
        self.blocksInDesign.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.modelInDesign= QStandardItemModel(self)
        self.modelInDesign.setHorizontalHeaderItem(0, QStandardItem("Blocks in current design"))
        self.blocksInDesign.setModel(self.modelInDesign)
        self.blocksInDesign.move(710,10)
        self.blocksInDesign.setFixedSize(250,400)

        self.setFixedSize(980, 460)
        self.setWindowTitle("uhd_image_builder.py GUI")
        self.show()

    ##################################################
    # Slots and functions/actions
    ##################################################
    @pyqtSlot()
    def addToDesign(self):
        index = self.blocksAvailable.currentIndex()
        word = self.blocksAvailable.model().data(index)
        element = QStandardItem(word)
        self.modelInDesign.appendRow(element)

    @pyqtSlot()
    def removeFromDesign(self):
        index = self.blocksInDesign.currentIndex()
        self.modelInDesign.removeRow(index.row())

    @pyqtSlot()
    def showFile(self):
        self.instFile = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
                self.target, 'rfnoc_ce_auto_inst_' + self.device.lower() + '.v')
        if (self.genCommand(False)):
            os.system("xdg-open " + self.instFile)

    @pyqtSlot()
    def genBit(self):
        self.genCommand(True)

    @pyqtSlot()
    def ootlist(self):
        index = self.targets.currentIndex()
        self.buildTarget = str(self.targets.model().data(index))
        self.device = self.buildTarget[:4]
        if self.device == 'X310' or self.device == 'X300':
            self.target = 'x300'
            self.max_allowed_blocks = 10
        elif self.device =='E310':
            self.target = 'e300'
            self.max_allowed_blocks = 6
        ootSources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
            self.target, 'Makefile.srcs')
        self.showList(self.OOT, self.target, ootSources)

    @pyqtSlot()
    def fileDiag(self):
        appendDir= []
        filename = QFileDialog.getOpenFileName(self, 'Open File', '')
        if len(filename) > 0:
            appendDir.append(os.path.join(os.path.dirname(
                os.path.join("", str(filename))), ''))
            uhd_image_builder.append_item_into_file(self.device, appendDir)
            ootSources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
                self.target, 'Makefile.srcs')
            self.populateList(self.OOT, ootSources)

    @pyqtSlot()
    def fileGRCDiag(self):
        filename = QFileDialog.getOpenFileName(self, 'Open File', '/')
        if len(filename) > 0:
            self.GRCpopulateList(self.modelInDesign,filename)

    def showNoSrcsWarning(self, block_to_add):
        # Create Warning message window
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Warning)
        msg.setText("The following blocks are in your design but their sources"\
            " have not been added: \n\n {0}. \n\nPlease be sure of adding them"\
            "before continuing. Would you like to add them now?"\
            "".format(block_to_add))
        msg.setWindowTitle("No sources for design")
        YesBtn = msg.addButton("Yes", QMessageBox.YesRole)
        NoBtn = msg.addButton("No", QMessageBox.NoRole)
        msg.exec_()
        if msg.clickedButton() == YesBtn:
            self.fileDiag()
            return False
        else:
            return True

    def showNoBlocksWarning(self, NumberOfBlocks):
        # Create Warning message window
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Warning)
        msg.setText("There are no Blocks in the current design")
        msg.exec_()

    def showToManyBlocksWarning(self, NumberOfBlocks):
        # Create Warning message window
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Warning)
        msg.setText("You added {} blocks while the maximum allowed blocks for"\
                " a {} device is {}. Please remove some of the blocks to "\
                "continue with the design".format(NumberOfBlocks,
                    self.device, self.max_allowed_blocks))
        msg.exec_()

    def iterTree(self, model, output, parent = QModelIndex()):
        for i in range(model.rowCount(parent)):
            index = model.index(i, 0, parent)
            item = model.data(index)
            output.append(str(item))
            if model.hasChildren(index):
                self.iterTree(model, output, index)
        return output

    def showList(self, parent, target, files):
        parent.setText('OOT Blocks for {} devices'.format(target.upper()))
        self.populateList(parent, files)

    def populateList(self,parent,files):
        #clean the list before populating it again
        parent.removeRows(0, parent.rowCount())
        suffix = '.v \\\n'
        with open(files) as f:
            blocks = f.readlines()
        for element in blocks:
            if element.endswith(suffix) and 'noc_block' in element :
                element = element[:-len(suffix)]
                block = QStandardItem(element.partition('noc_block_')[2])
                parent.appendRow(block)

    def GRCpopulateList(self, parent, files):
        tree = ET.parse(files)
        root = tree.getroot()
        for blocks in root.iter('block'):
            for param in blocks.iter('param'):
                for key in param.iter('key'):
                    if 'fpga_module_name' in key.text:
                        if param.findtext('value') == 'noc_block_radio_core': continue
                        block = QStandardItem(param.findtext('value').partition('noc_block_')[2])
                        parent.appendRow(block)

    def populateTargets(self, selectedTarget):
        s =  '0_RFNOC'
        buildTargets = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',
                selectedTarget, 'Makefile')
        with open(buildTargets, 'r') as f:
            text = f.readlines()
            for lines in text:
                lines = lines.partition(':')[0]
                if s in lines:
                    target = QStandardItem(lines)
                    self.modelTargets.appendRow(target)

    def genCommand(self, flag = False):
        availables = []
        toDesign = []
        notin = []
        maxFlag = False
        notInFlag = False
        availables = self.iterTree(self.modelBlocksAvailable, availables)
        self.max_allowed_blocks = 10 if self.target == 'x300' else 6
        Ncurrent_blocks = self.modelInDesign.rowCount()
        # Check if there are sources for the blocks in current design
        if Ncurrent_blocks == 0:
            self.showNoBlocksWarning(Ncurrent_blocks)
            notInFlag = True
        else:
            for i in range(self.modelInDesign.rowCount()):
                block_to_add = self.blocksInDesign.model().data(
                        self.blocksInDesign.model().index(i,0))
                if str(block_to_add) not in availables:
                        notin.append(str(block_to_add))
                else:
                    toDesign.append(str(block_to_add))
            # Check whether the number of blocks exceeds the stated maximum
            if Ncurrent_blocks > self.max_allowed_blocks:
                self.showToManyBlocksWarning(Ncurrent_blocks)
                maxFlag = True
            elif Ncurrent_blocks < self.max_allowed_blocks and self.fillWithFifos.isChecked():
                for i in range(self.max_allowed_blocks - Ncurrent_blocks):
                    toDesign.append('axi_fifo_loopback')
        if len(notin) > 0:
            self.showNoSrcsWarning(notin)
            return
        if not (notInFlag or maxFlag):
            com = ' '.join(toDesign)
            command = "./uhd_image_builder.py " + com + ' -d ' + self.device + ' -t ' + self.buildTarget
            if flag == False:
                command = command + ' -o ' + self.instFile
            if self.vivGui.isChecked():
                command = command + ' -g'
            if self.cleanall.isChecked():
                command = command + ' -c'
            print(command)
            os.system(command)
            return True
        else:
            return False

def main():
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
