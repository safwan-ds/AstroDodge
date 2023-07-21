from time import time


class State:
    def __init__(self, app):
        self.app = app

    def add(self):
        self.app.state_stack.append(self)

    def remove(self):
        try:
            self.app.state_stack.remove(self)
        except ValueError:
            ...

    def get_input(self):
        ...

    def update(self):
        self.get_input()
