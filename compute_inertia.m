function [] = compute_inertia(outdir)
    vols = zeros(22,1);
    coms = zeros(22, 3);
    a_MoI = zeros(22, 3, 3);
    Is = zeros(22, 6);
    density = 985;
    jt = load(strcat(outdir, '/joints.txt'));
    for i=0:21
        vtx = load(sprintf(strcat(outdir, '/body_parts/vertices-%02d.txt'), i));
    %     hold on
    %     scatter3(vtx(:,1),vtx(:,2),vtx(:,3));
        vtx = vtx - repmat(jt(i+1,:), size(vtx,1), 1); % in joint's local frame
        [k,vol] = convhull(vtx);
        vols(i+1) = vol;

        [I, ~, com, ~] = inertia_tensor(vtx, k);
        I = I * density;
        %disp(join([string(I(1,1)), string(I(2,2)), string(I(3,3)), string(I(1,2)), string(I(1,3)), string(I(2,3))], ", "))
        Is(i+1,:) = [I(1,1), I(2,2), I(3,3), I(1,2), I(1,3), I(2,3)];
        a_MoI(i+1,:,:) = I;
        coms(i+1,:) = com;

    %     % why not working?
    %     T = delaunayn(vtx);
    %     n = size(T,1);
    %     W = zeros(n,1);
    %     C=0;
    %     for m = 1:n
    %         sp = vtx(T(m,:),:);
    %         [~,W(m)]=convhulln(sp);
    %         C = C + W(m) * mean(sp);
    %     end
    %     C=C./sum(W);
    %     com(i+1,:) = C;
    %     
    %     MoI = zeros(3,3);
    %     for m = 1:n
    %         sp = vtx(T(m,:),:);
    %         MoI = MoI + momentOfInertia(sp, C);
    %     end
    %     MoI
    end
    mass = vols * density;
    save(strcat(outdir, '/mass.txt'), 'mass', '-ascii');
    save(strcat(outdir, '/center_of_mass.txt'), 'coms', '-ascii');
    save(strcat(outdir, '/inertia_tensor.txt'), 'Is', '-ascii');
end

% figure
% joints=load('/home/kevin/Documents/research/AMASS-data/joints.txt');
% scatter3(joints(:,1), joints(:,2), joints(:,3));
% for i=0:21
%     tp=text(joints(i+1, 1), joints(i+1, 2), string(i));
%     tp.FontSize=16;
% end

% anything wrong with code below?

function MoI = momentOfInertia(sp, com)
    spl = sp - repmat(com, 4,1);
    x = spl(:,1);
    y = spl(:,2);
    z = spl(:,3);
    J = [
        x(2)-x(1), x(3)-x(1), x(4)-x(1);
        y(2)-y(1), y(3)-y(1), y(4)-y(1);
        z(2)-z(1), z(3)-z(1), z(4)-z(1);
        ];
    u = 985;
    a = combine(y,y) + combine(z,z) / 60;
    b = combine(x,x) + combine(z,z) / 60;
    c = combine(x,x) + combine(y,y) / 60;
    ap = combine(y,z) + combine(z,y) / 120;
    bp = combine(x,z) + combine(z,x) / 120;
    cp = combine(x,y) + combine(y,x) / 120;
    
    MoI = u * abs(det(J))...
        * [ a  -bp -cp;
           -bp  b  -ap;
           -cp -ap  c];
end

function v = combine(a, b)
    v = a(1)*b(1) + a(1)*b(2) + a(2)*b(2) + a(1)*b(3) + a(2)*b(3) + a(3)*b(3)...
        + a(1)*b(4) + a(2)*b(4) + a(3)*b(4) + a(4)*b(4);
end
