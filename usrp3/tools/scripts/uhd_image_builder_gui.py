#!/usr/bin/env python
"""
 Copyright 2016-2017 Ettus Research

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

from __future__ import print_function
import sip
sip.setapi('QVariant', 2)
import os
import sys
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL)
import xml.etree.ElementTree as ET
import uhd_image_builder
import sip
sip.setapi('QVariant', 2)
from PyQt4 import QtGui
from PyQt4.QtCore import pyqtSlot
from PyQt4.QtCore import Qt, QModelIndex, SIGNAL

class MainWindow(QtGui.QWidget):
    """
    UHD_IMAGE_BUILDER
    """
    # pylint: disable=too-many-instance-attributes

    def __init__(self):
        super(MainWindow, self).__init__()
        ##################################################
        # Initial Values
        ##################################################
        self.target = 'x300'
        self.device = 'x310'
        self.build_target = 'X310_RFNOC_HG'
        self.max_allowed_blocks = 10
        self.instantiation_file = os.path.join(uhd_image_builder.get_scriptpath(),
                                               '..', '..', 'top', self.target,
                                               'rfnoc_ce_auto_inst_' + self.device.lower() +
                                               '.v')
        # List of blocks that are part of our library but that do not take place
        # on the process this tool provides
        self.blacklist = ['noc_block_radio_core', 'noc_block_axi_dma_fifo', 'noc_block_pfb']

        self.init_gui()

    def init_gui(self):
        """
        Initializes GUI init values and constants
        """
        # pylint: disable=too-many-statements

        ettus_sources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'lib',\
            'rfnoc', 'Makefile.srcs')

        ##################################################
        # Buttons
        ##################################################
        oot_btn = QtGui.QPushButton('Add OOT Blocks', self)
        oot_btn.setToolTip('Add your custom Out-of-tree blocks')
        oot_btn.move(80, 420)
        from_grc_btn = QtGui.QPushButton('Import from GRC', self)
        from_grc_btn.move(340, 420)
        show_file_btn = QtGui.QPushButton('Show instantiation File', self)
        show_file_btn.move(540, 420)
        add_btn = QtGui.QPushButton('>>', self)
        add_btn.move(550, 100)
        add_btn.setFixedSize(150, 50)
        rem_btn = QtGui.QPushButton('<<', self)
        rem_btn.move(550, 220)
        rem_btn.setFixedSize(150, 50)
        gen_bit_btn = QtGui.QPushButton('Generate .bit file', self)
        gen_bit_btn.move(775, 420)

        ##################################################
        # Checkbox
        ##################################################
        self.fill_with_fifos = QtGui.QCheckBox('Fill with FIFOs', self)
        self.fill_with_fifos.move(560, 300)
        self.viv_gui = QtGui.QCheckBox('Open Vivado GUI', self)
        self.viv_gui.move(560, 320)
        self.cleanall = QtGui.QCheckBox('Clean IP', self)
        self.cleanall.move(560, 340)

        ##################################################
        # Connection of the buttons with their signals
        ##################################################
        oot_btn.clicked.connect(self.file_dialog)
        from_grc_btn.clicked.connect(self.file_grc_dialog)
        show_file_btn.clicked.connect(self.show_file)
        add_btn.clicked.connect(self.add_to_design)
        rem_btn.clicked.connect(self.remove_from_design)
        gen_bit_btn.clicked.connect(self.generate_bit)

        ##################################################
        # Panels - QTreeModels
        ##################################################
        ### Far-left Panel: Build targets
        self.targets = QtGui.QTreeView(self)
        self.targets.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)
        self.model_targets = QtGui.QStandardItemModel(self)
        self.model_targets.setHorizontalHeaderItem(0, QtGui.QStandardItem("Select build target"))
        self.targets.setModel(self.model_targets)
        self.populate_target('x300')
        self.populate_target('e300')
        self.targets.setCurrentIndex(self.model_targets.index(0, 0))
        self.targets.show()
        self.targets.move(20, 10)
        self.targets.setFixedSize(250, 400)

        ### Central Panel: Available blocks
        ### Create tree to categorize Ettus Block and OOT Blocks in different lists
        self.blocks_available = QtGui.QTreeView(self)
        self.blocks_available.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)
        self.blocks_available.setContextMenuPolicy(Qt.CustomContextMenu)
        ettus_blocks = QtGui.QStandardItem("Ettus-provided Blocks")
        self.populate_list(ettus_blocks, ettus_sources)

        oot_sources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
            'x300', 'Makefile.srcs')
        self.oot = QtGui.QStandardItem("OOT Blocks for X300 devices")
        self.populate_list(self.oot, oot_sources)
        self.model_blocks_available = QtGui.QStandardItemModel(self)
        self.model_blocks_available.appendRow(ettus_blocks)
        self.model_blocks_available.appendRow(self.oot)
        self.model_blocks_available.setHorizontalHeaderItem(
            0, QtGui.QStandardItem("List of blocks available")
            )
        self.blocks_available.setModel(self.model_blocks_available)
        self.blocks_available.move(290, 10)
        self.blocks_available.setFixedSize(250, 400)

        self.targets.connect(self.targets.selectionModel(),
                             SIGNAL('selectionChanged(QItemSelection, QItemSelection)'),
                             self.ootlist) #check when the selection of this changes

        ### Far-right Panel: Blocks in current design
        self.blocks_in_design = QtGui.QTreeView(self)
        self.blocks_in_design.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)
        self.model_in_design = QtGui.QStandardItemModel(self)
        self.model_in_design.setHorizontalHeaderItem(
            0, QtGui.QStandardItem("Blocks in current design"))
        self.blocks_in_design.setModel(self.model_in_design)
        self.blocks_in_design.move(710, 10)
        self.blocks_in_design.setFixedSize(250, 400)

        self.setFixedSize(980, 460)
        self.setWindowTitle("uhd_image_builder.py GUI")
        self.show()

    ##################################################
    # Slots and functions/actions
    ##################################################
    @pyqtSlot()
    def add_to_design(self):
        """
        Adds blocks from the 'available' pannel to the list to be added
        into the design
        """
        index = self.blocks_available.currentIndex()
        word = self.blocks_available.model().data(index)
        element = QtGui.QStandardItem(word)
        self.model_in_design.appendRow(element)

    @pyqtSlot()
    def remove_from_design(self):
        """
        Removes blocks from the list that is to be added into the design
        """
        index = self.blocks_in_design.currentIndex()
        self.model_in_design.removeRow(index.row())

    @pyqtSlot()
    def show_file(self):
        """
        Show the rfnoc_ce_auto_inst file in the default text editor
        """
        if self.generate_command(False):
            os.system("xdg-open " + self.instantiation_file)

    @pyqtSlot()
    def generate_bit(self):
        """
        Runs the FPGA .bit generation command
        """
        self.generate_command(True)

    @pyqtSlot()
    def ootlist(self):
        """
        Lists the Out-of-tree module blocks
        """
        index = self.targets.currentIndex()
        self.build_target = str(self.targets.model().data(index))
        self.device = self.build_target[:4]
        if self.device == 'X310' or self.device == 'X300':
            self.target = 'x300'
            self.max_allowed_blocks = 10
        elif self.device == 'E310':
            self.target = 'e300'
            self.max_allowed_blocks = 6
        oot_sources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
            self.target, 'Makefile.srcs')
        self.show_list(self.oot, self.target, oot_sources)

    @pyqtSlot()
    def file_dialog(self):
        """
        Opens a dialog window to add manually the Out-of-tree module blocks
        """
        append_directory = []
        filename = QtGui.QFileDialog.getOpenFileName(self, 'Open File', '')
        if len(filename) > 0:
            append_directory.append(os.path.join(os.path.dirname(
                os.path.join("", str(filename))), ''))
            uhd_image_builder.append_item_into_file(self.device, append_directory)
            oot_sources = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',\
                self.target, 'Makefile.srcs')
            self.populate_list(self.oot, oot_sources)

    @pyqtSlot()
    def file_grc_dialog(self):
        """
        Opens a dialog window to add manually the GRC description file, from where
        the RFNoC blocks will be parsed and added directly into the "Design" pannel
        """
        filename = QtGui.QFileDialog.getOpenFileName(self, 'Open File', '/')
        if len(filename) > 0:
            self.grc_populate_list(self.model_in_design, filename)

    def show_no_srcs_warning(self, block_to_add):
        """
        Shows a warning message window when no sources are found for the blocks that
        are in the design pannel
        """
        # Create Warning message window
        msg = QtGui.QMessageBox()
        msg.setIcon(QtGui.QMessageBox.Warning)
        msg.setText("The following blocks are in your design but their sources"\
            " have not been added: \n\n {0}. \n\nPlease be sure of adding them"\
            "before continuing. Would you like to add them now?"\
            "".format(block_to_add))
        msg.setWindowTitle("No sources for design")
        yes_btn = msg.addButton("Yes", QtGui.QMessageBox.YesRole)
        no_btn = msg.addButton("No", QtGui.QMessageBox.NoRole)
        msg.exec_()
        if msg.clickedButton() == yes_btn:
            self.file_dialog()
            return False
        elif msg.clickedButton() == no_btn:
            return True

    @staticmethod
    def show_no_blocks_warning():
        """
        Shows a warning message window when no blocks are found in the 'design' pannel
        """
        # Create Warning message window
        msg = QtGui.QMessageBox()
        msg.setIcon(QtGui.QMessageBox.Warning)
        msg.setText("There are no Blocks in the current design")
        msg.exec_()

    def show_too_many_blocks_warning(self, number_of_blocks):
        """
        Shows a warning message window when too many blocks are found in the 'design' pannel
        """
        # Create Warning message window
        msg = QtGui.QMessageBox()
        msg.setIcon(QtGui.QMessageBox.Warning)
        msg.setText("You added {} blocks while the maximum allowed blocks for"\
                " a {} device is {}. Please remove some of the blocks to "\
                "continue with the design".format(number_of_blocks,
                                                  self.device, self.max_allowed_blocks))
        msg.exec_()

    def iter_tree(self, model, output, parent=QModelIndex()):
        """
        Iterates over the Index tree
        """
        for i in range(model.rowCount(parent)):
            index = model.index(i, 0, parent)
            item = model.data(index)
            output.append(str(item))
            if model.hasChildren(index):
                self.iter_tree(model, output, index)
        return output

    def show_list(self, parent, target, files):
        """
        Shows the Out-of-tree blocks that are available for a given device
        """
        parent.setText('OOT Blocks for {} devices'.format(target.upper()))
        self.populate_list(parent, files)

    def populate_list(self, parent, files):
        """
        Populates the pannels with the blocks that are listed in the Makefile.srcs
        of our library
        """
        #clean the list before populating it again
        parent.removeRows(0, parent.rowCount())
        suffix = '.v \\\n'
        with open(files) as fil:
            blocks = fil.readlines()
        for element in blocks:
            if element.endswith(suffix) and 'noc_block' in element:
                element = element[:-len(suffix)]
                if element not in self.blacklist:
                    block = QtGui.QStandardItem(element.partition('noc_block_')[2])
                    parent.appendRow(block)

    def grc_populate_list(self, parent, files):
        """
        Populates the 'Design' list with the RFNoC blocks found in a GRC file
        """
        tree = ET.parse(files)
        root = tree.getroot()
        for blocks in root.iter('block'):
            for param in blocks.iter('param'):
                for key in param.iter('key'):
                    if 'fpga_module_name' in key.text:
                        if param.findtext('value') in self.blacklist:
                            continue
                        block = QtGui.QStandardItem(param.findtext('value').\
                                partition('noc_block_')[2])
                        parent.appendRow(block)

    def populate_target(self, selected_target):
        """
        Parses the Makefile available and lists the build targets into the left pannel
        """
        suffix = '0_RFNOC'
        build_targets = os.path.join(uhd_image_builder.get_scriptpath(), '..', '..', 'top',
                                     selected_target, 'Makefile')
        with open(build_targets, 'r') as fil:
            text = fil.readlines()
            for lines in text:
                lines = lines.partition(':')[0]
                if suffix in lines:
                    target = QtGui.QStandardItem(lines)
                    self.model_targets.appendRow(target)

    def generate_command(self, flag=False):
        """
        generates the FPGA build command
        """
        # pylint: disable=too-many-branches
        availables = []
        to_design = []
        notin = []
        max_flag = False
        not_in_flag = False
        availables = self.iter_tree(self.model_blocks_available, availables)
        self.max_allowed_blocks = 10 if self.target == 'x300' else 6
        num_current_blocks = self.model_in_design.rowCount()
        # Check if there are sources for the blocks in current design
        if num_current_blocks == 0:
            self.show_no_blocks_warning()
            not_in_flag = True
        else:
            for i in range(self.model_in_design.rowCount()):
                block_to_add = self.blocks_in_design.model().data(
                    self.blocks_in_design.model().index(i, 0))
                if str(block_to_add) not in availables:
                    notin.append(str(block_to_add))
                else:
                    to_design.append(str(block_to_add))
            # Check whether the number of blocks exceeds the stated maximum
            if num_current_blocks > self.max_allowed_blocks:
                self.show_too_many_blocks_warning(num_current_blocks)
                max_flag = True
            elif num_current_blocks < self.max_allowed_blocks and self.fill_with_fifos.isChecked():
                for i in range(self.max_allowed_blocks - num_current_blocks):
                    to_design.append('axi_fifo_loopback')
        if len(notin) > 0:
            self.show_no_srcs_warning(notin)
            return
        if not (not_in_flag or max_flag):
            com = ' '.join(to_design)
            command = "./uhd_image_builder.py " + com + ' -d ' + self.device + \
                      ' -t ' + self.build_target
            if flag is False:
                command = command + ' -o ' + self.instantiation_file
            if self.viv_gui.isChecked():
                command = command + ' -g'
            if self.cleanall.isChecked():
                command = command + ' -c'
            print(command)
            os.system(command)
            return True
        else:
            return False

def main():
    """
    Main GUI method
    """
    app = QtGui.QApplication(sys.argv)
    _window = MainWindow()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
