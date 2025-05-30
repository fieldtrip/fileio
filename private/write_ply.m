function write_ply(fn, pnt, tri, format)

% WRITE_PLY writes triangles, tetrahedrons or hexahedrons to a Stanford *.ply format file
%
% Use as
%   write_ply(filename, vertex, element)
%
% Documentation is provided on
%   http://paulbourke.net/dataformats/ply/
%   http://en.wikipedia.org/wiki/PLY_(file_format)
%
% See also READ_PLY, READ_VTK, WRITE_VTK

% Copyright (C) 2012, Robert Oostenveld
% 
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% the element are described as
%   Mx3 list of vertices for triangles
%   Mx4 list of vertices for tetrahedrons
%   Mx8 list of vertices for hexahedrons

if nargin<4
  format = 'ascii';
end

if size(tri,2)==4
  % describe the sides of the tetrahedrons as polygon surface elements
  % see http://bugzilla.fieldtriptoolbox.org/show_bug.cgi?id=1836
  tri = [
    tri(:,[3 2 1])
    tri(:,[2 4 1])
    tri(:,[3 4 2])
    tri(:,[4 3 1])
    ];
elseif size(tri,2)==8
  % describe the sides of the hexahedrons as polygon surface elements
  % see http://bugzilla.fieldtriptoolbox.org/show_bug.cgi?id=1836
  tri = [
    tri(:,[4 3 2 1])
    tri(:,[1 2 6 5])
    tri(:,[3 7 6 2])
    tri(:,[4 8 7 3])
    tri(:,[5 8 4 1])
    tri(:,[6 7 8 5])
    ];
end

if strcmp(format, 'ascii')
  fid = fopen_or_error(fn, 'wt');
else
  fid = fopen_or_error(fn, 'wb');
end

npnt = size(pnt,1);
ntri = size(tri,1);
if numel(tri)>0
  % MATLAB indexes start at 1, inside the file they start at 0
  tri = tri-1;
end

% write the header
fprintf(fid, 'ply\n');
if  strcmp(format, 'ascii')
  fprintf(fid, 'format ascii 1.0\n');
else
  [c, m, e] = computer;
  if e=='L'
    fprintf(fid, 'format binary_little_endian 1.0\n');
  elseif e=='B'
    fprintf(fid, 'format binary_big_endian 1.0\n');
  end
end

fprintf(fid, 'element vertex %d\n', npnt);
fprintf(fid, 'property float x\n');
fprintf(fid, 'property float y\n');
fprintf(fid, 'property float z\n');
fprintf(fid, 'element face %d\n', ntri);
fprintf(fid, 'property list uchar int vertex_index\n');
fprintf(fid, 'end_header\n');

if strcmp(format, 'ascii')
  % write the vertex points
  fprintf(fid, '%f\t%f\t%f\n', pnt');
  num = size(tri,2);
  switch num
    case 3
      fprintf(fid, '3\t%d\t%d\t%d\n', tri');
    case 4
      fprintf(fid, '4\t%d\t%d\t%d\t%d\n', tri');
    case 5
      fprintf(fid, '5\t%d\t%d\t%d\t%d\n', tri');
    case 6
      fprintf(fid, '6\t%d\t%d\t%d\t%d\n', tri');
    case 7
      fprintf(fid, '7\t%d\t%d\t%d\t%d\n', tri');
    case 8
      fprintf(fid, '8\t%d\t%d\t%d\t%d\n', tri');
    case 9
      fprintf(fid, '9\t%d\t%d\t%d\t%d\n', tri');
    otherwise
      ft_error('unsupported size for polygons (%d)', num);
  end % case
else
  fwrite(fid, pnt', 'single');      % float
  num = size(tri,2);
  for i=1:size(tri,1)
    fwrite(fid, num, 'uint8');      % uchar
    fwrite(fid, tri(i,:), 'int32'); % int
  end
end

fclose(fid);
  
