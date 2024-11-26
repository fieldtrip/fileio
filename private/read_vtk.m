function [pos, tri, attr] = read_vtk(fn)

% READ_VTK reads a triangulation from a VTK (Visualisation ToolKit) format file
% Supported are triangles and other polygons.
%
% Use as
%   [pnt, tri] = read_vtk(filename)
%
% See also WRITE_VTK

% Copyright (C) 2002-2023, Robert Oostenveld
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

fid = fopen_or_error(fn, 'rt');

line = fgetl(fid);
if ~ischar(line) || ~startsWith(line, '# vtk DataFile Version')
  error('Unexpected first line in file, is it a valid VTK file ?');
end

line = fgetl(fid);
if ~ischar(line)
  error('Unexpected line in file, is it a valid VTK file ?');
end

format = fgetl(fid);
if ~ismember(format, {'ASCII' 'BINARY'})
  % should be either ASCII or BINARY
  error('The file should be either ASCII or BINARY');
end

% ensure that this is a DATASET POLYDATA filetype, which is currently the only supported format
line = '';
while ~contains(line, 'DATASET') 
  line = fgetl(fid);
end

assert(isequal(line, 'DATASET POLYDATA'), 'Only files containing POLYDATA are currently supported');

% next we expect the definition of the POINTS
npos = 0;
while (~npos)
  line = fgetl(fid);
  if contains(line, 'POINTS')
    npos = sscanf(line, 'POINTS %d float');
  end
end

pos = fscanf(fid, '%f', 3*npos);
pos = reshape(pos, [3 npos])';

tri = [];

% next we can have VERTICES, POLYGONS, TRIANGLE_STRIPS, and LINES, assuming
% that the next line at the current location in the files contains a known
% keyword, also consider POINT_DATA as data_attribute, it is assumed to
% follow the geometry description
while ~isequal(line, -1)
  line = fgetl(fid);
  while isempty(line)
    line = fgetl(fid);
  end

  if startsWith(line, 'POLYGONS')
    tmp = sscanf(line, 'POLYGONS %d %d');
    ntri  = tmp(1);          % number of triangles
    nvert = tmp(2)/ntri - 1; % number of vertices per polygon
    
    tri = zeros(ntri, nvert+1);
    for i=1:ntri
      tri(i,:) = fscanf(fid, '%d', nvert+1)';
    end
    % drop the first column
    tri = tri(:,2:(nvert+1)) + 1; % start counting at 1

  elseif startsWith(line, 'VERTICES')
    tmp = sscanf(line, 'VERTICES %d %d');
    nvert   = tmp(1);
    sumvert = tmp(2);
    data    = fscanf(fid, '%d', sumvert);
    vert    = cell(nvert,1);
    offset  = 1;
    for k = 1:nvert
      vert{k} = data(offset+1+(0:(data(offset)-1))) + 1; % start counting at 1
      offset  = offset+1+numel(vert{k});
    end
    
  elseif startsWith(line, 'TRIANGLE_STRIPS')
    % to do
  elseif startsWith(line, 'LINES')
    % to do
  elseif startsWith(line, 'POINT_DATA')
    break;
  end
end

% deal with attributes
if ischar(line) && startsWith(line, 'POINT_DATA')
  line = fgetl(fid);
  if startsWith(line, 'VECTORS')
    % assume Npointsx3 floats
    for i=1:npos
      attr(i,:) = fscanf(fid, '%f', 3)';
    end
  end
else
  attr = [];
end

fclose(fid);
