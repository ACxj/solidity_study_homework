// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    uint256 private constant MAX_TODOS = 100;

    struct Todo {
        uint256 id;
        string content;
        bool isCompleted;
        uint256 createdAt;
    }

    mapping(address => Todo[]) private userTodos;
    mapping(address => uint256) private todoIdCounters;

    error TodoNotFound(uint256 id);
    error MaxTodosReached();
    error AlreadyCompleted(uint256 id);
    error AlreadyDeleted();

    event TodoAdded(address indexed user, uint256 id, string content);
    event TodoCompleted(address indexed user, uint256 id);
    event TodoDeleted(address indexed user, uint256 id);

    function addTodo(string memory content) external {
        Todo[] storage todos = userTodos[msg.sender];
        if (todos.length >= MAX_TODOS) revert MaxTodosReached();

        uint256 id = ++todoIdCounters[msg.sender];
        todos.push(Todo({
            id: id,
            content: content,
            isCompleted: false,
            createdAt: block.timestamp
        }));

        emit TodoAdded(msg.sender, id, content);
    }

    function completeTodo(uint256 id) external {
        Todo[] storage todos = userTodos[msg.sender];
        for (uint256 i = 0; i < todos.length; ++i) {
            if (todos[i].id == id) {
                if (todos[i].isCompleted) revert AlreadyCompleted(id);
                todos[i].isCompleted = true;
                emit TodoCompleted(msg.sender, id);
                return;
            }
        }
        revert TodoNotFound(id);
    }

    function deleteTodo(uint256 id) external {
        Todo[] storage todos = userTodos[msg.sender];
        for (uint256 i = 0; i < todos.length; ++i) {
            if (todos[i].id == id) {
                if (bytes(todos[i].content).length == 0) revert AlreadyDeleted();
                todos[i].content = "";
                todos[i].isCompleted = false;
                emit TodoDeleted(msg.sender, id);
                return;
            }
        }
        revert TodoNotFound(id);
    }

    function getTodos() external view returns (Todo[] memory) {
        Todo[] memory todos = userTodos[msg.sender];
        uint256 count;
        for (uint256 i = 0; i < todos.length; ++i) {
            if (bytes(todos[i].content).length > 0) {
                ++count;
            }
        }

        Todo[] memory result = new Todo[](count);
        uint256 index;
        for (uint256 i = 0; i < todos.length; ++i) {
            if (bytes(todos[i].content).length > 0) {
                result[index++] = todos[i];
            }
        }
        return result;
    }

    function getCompletedTodos() external view returns (Todo[] memory) {
        Todo[] storage todos = userTodos[msg.sender];
        uint256 count;
        for (uint256 i = 0; i < todos.length; ++i) {
            if (todos[i].isCompleted && bytes(todos[i].content).length > 0) {
                ++count;
            }
        }

        Todo[] memory result = new Todo[](count);
        uint256 index;
        for (uint256 i = 0; i < todos.length; ++i) {
            if (todos[i].isCompleted && bytes(todos[i].content).length > 0) {
                result[index++] = todos[i];
            }
        }
        return result;
    }

    function getTodoCount() external view returns (uint256 active, uint256 completed, uint256 deleted) {
        Todo[] storage todos = userTodos[msg.sender];
        for (uint256 i = 0; i < todos.length; ++i) {
            if (bytes(todos[i].content).length == 0) {
                ++deleted;
            } else if (todos[i].isCompleted) {
                ++completed;
            } else {
                ++active;
            }
        }
    }
}