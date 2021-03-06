clear;
close all;
clc;

%% Config
erasureRate = 0.60;
overhead = 2;
sourcefile = 'tunacoma.jpg';
recoveredfile = 'recoveredKitty.jpg';

fprintf('Erasure rate = %f and overhead of %d \n', erasureRate, overhead);

%% Emulate sender side
% open kitty image file
fid = fopen(sourcefile, 'r');
kitty = fread(fid, inf, '*uint8')';
fclose(fid);

fprintf('Emulating Sender -- Encoding ... \n');
[ SourceSymbols, RepairSymbols, numSouceSymbols, padding ] = RaptorEncoder( kitty, erasureRate, overhead);

ReceivedSymbols = SourceSymbols;
%% Emulate receiver side
fprintf('\n\n\n'); 
fprintf('Emulating channel erasure... \n'); 

loss = ceil(erasureRate * numSouceSymbols);
lossidx = randi([1, numSouceSymbols], loss, 1);
lossidx = unique(lossidx);

%throw away data
for i = 1 : length(lossidx)
    ReceivedSymbols(lossidx(i), :) = 0;
    fprintf('Removing symbol ... %d \n', lossidx(i));
end


[numRepair, lenRepair] = size(RepairSymbols);

%% assuming no missing repair symbols
repairIdx = 1 : 1 : numRepair;
fprintf('\n\n\n'); 
fprintf('Emulating Receiver -- Decoding ... \n');
RecoveredSymbols = RaptorDecoder(ReceivedSymbols, numSouceSymbols, lossidx, RepairSymbols, repairIdx, padding);

fprintf('confirming received and source ... \n');
[wid, len] = size(SourceSymbols);

for row = 1 : wid
    for col = 1 : len
        
        if(RecoveredSymbols(row, col) ~= SourceSymbols(row, col))
            fprintf('mismatch found ... (%i, %i) \n', row, col);
            return;
        end
        
    end
end

fprintf('All symbols match! Job done! \n');

[w, l] = size(RecoveredSymbols);
numOfSymbols = w * l - padding;

delete(recoveredfile);
fid = fopen(recoveredfile, 'w');

counter = 0;
for n = 1 : w
    for nn = 1 : l
        
        fwrite(fid, RecoveredSymbols(n, nn), 'uint8');
        
        if(counter == numOfSymbols)
            return;
        end
    end
end

fclose(fid);


%% display the results
figure('name', sourcefile);
[original, map1] = imread(sourcefile);
imshow(original, 'Border', 'tight');

figure('name', [recoveredfile, ' w/ erasure rate of ', num2str(erasureRate)]);
[recovered, map2] = imread(recoveredfile);
imshow(recovered, 'Border', 'tight');


