## Copyright (C) 2015 Julian Arnold
## 
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} derotate_ofdm_symbol (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Julian Arnold <julian@juarnold-t440>
## Created: 2015-02-06
## Pilots in carrier -21, -7, 7, 21
## Pilots are 1 1 1 -1 modulated by the polarity bit

function [S_out] = derotate_ofdm_symbol (S, S_pilots, polarity)
  Phi_error = [arg(S_pilots(1)*polarity) arg(S_pilots(2)*polarity) arg(S_pilots(3)*polarity) arg(-1*(S_pilots(4)*polarity))];
  #Averaging pilots  results in weierd behaviour... E.g.  + + + - can result in problems
  #Therefre use this methode or use phase tracking so that the phase error can not become too large
  S_out = [S(1:14).*exp(-j.*(Phi_error(1))) S(15:28).*exp(-j.*(Phi_error(2))) S(29:42).*exp(-j.*(Phi_error(3))) S(43:end).*exp(-j.*(Phi_error(4)))];
  
endfunction
