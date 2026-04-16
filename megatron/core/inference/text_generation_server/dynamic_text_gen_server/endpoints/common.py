# Copyright (c) 2024, NVIDIA CORPORATION. All rights reserved.

import threading

import torch

from megatron.plugin.platform import get_platform

cur_platform = get_platform()

GENERATE_NUM = 0
LOCK = threading.Lock()


def send_do_generate():
    """Broadcasts a message to perform a generation to all tensor parallel ranks."""
    choice = torch.tensor([GENERATE_NUM], dtype=torch.long, device=cur_platform.current_device())
    torch.distributed.broadcast(choice, 0)
