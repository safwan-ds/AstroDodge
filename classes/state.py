from time import time


class State:
    def __init__(self, app):
        self.app = app

    def add(self):
        self.app.state_stack.append(self)

    def remove(self):
        self.app.state_stack.pop()
        self.app.state_time = time()

    def get_input(self):
        ...

    def update(self):
        self.get_input()
