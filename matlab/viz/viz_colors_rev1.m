function c = viz_colors_rev1()
%VIZ_COLORS_REV1 NTIA palette shared with the Python figures (python/viz/ntia_style.py).
%   c.text dark blue, c.accent light blue (the hero mark), c.alert purple
%   (worst case), c.context and c.light grays, c.panel light fill.
c.text = [22 51 83] / 255;          % #163353
c.accent = [86 116 196] / 255;      % #5674C4
c.alert = [110 79 146] / 255;       % #6E4F92
c.context = [138 141 145] / 255;    % #8A8D91
c.light = [201 204 208] / 255;      % #C9CCD0
c.panel = [232 233 234] / 255;      % #E8E9EA
c.font = 'Times New Roman';
end
