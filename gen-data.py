import argparse
import os
import torch
import numpy as np

from human_body_prior.body_model.body_model import BodyModel
from human_body_prior.tools.omni_tools import copy2cpu as c2c
from os import path as osp

parser = argparse.ArgumentParser()
parser.add_argument('-z', '--npz', action='store_true', help='indicate spec_file is a npz file')
parser.add_argument('-o', '--outdir', action='store', default="output",  help='output folder (default: output)')
parser.add_argument('spec_file')
args = parser.parse_args()

num_betas = 16
num_dmpls = 8

bindir = os.path.abspath(os.path.dirname(__file__))

#comp_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
comp_device = torch.device("cpu")

if args.npz:
    bdata = np.load(args.spec_file)
    subject_gender = bdata['gender']
    beta = torch.Tensor(np.repeat(bdata['betas'][:num_betas][np.newaxis], repeats=1, axis=0)).to(comp_device)
else:
    fh = open(args.spec_file, 'r')
    line = fh.readline()
    subject_gender = line.rstrip()
    line = fh.readline()
    beta = torch.Tensor(np.repeat(np.array(line.rstrip().split())[:num_betas][np.newaxis], repeats=1, axis=0)).to(comp_device)
    fh.close()

bm_fname = '{}/data/body_models/smplh/{}/model.npz'.format(bindir, subject_gender)
dmpl_fname = '{}/data/body_models/dmpls/{}/model.npz'.format(bindir, subject_gender)

bm = BodyModel(bm_fname=bm_fname, num_betas=num_betas, num_dmpls=num_dmpls, dmpl_fname=dmpl_fname).to(comp_device)

body_pose_beta = bm(betas=beta)

joints = c2c(body_pose_beta.Jtr[0])
np.savetxt(args.outdir + '/joints.txt', joints)

vertices=c2c(body_pose_beta.v[0])
np.savetxt(args.outdir + '/vertices.txt', vertices)
faces = c2c(bm.f)
np.savetxt(args.outdir + '/faces.txt', faces, fmt='%d')

bm_data = np.load(bm_fname)
np.savetxt(args.outdir + '/weights.txt', bm_data['weights'])
np.savetxt(args.outdir + '/kintree.txt', bm_data['kintree_table'], fmt="%d")
np.savetxt(args.outdir + '/parent_of_vertex.txt', np.argmax(bm_data['weights'], axis=1), fmt="%d")
