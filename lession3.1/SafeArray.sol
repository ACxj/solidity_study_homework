// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeArray {
    uint256 public constant MAX_LENGTH = 100;

    uint256[] public data;

    error ArrayFull();
    error InvalidIndex();
    error InvalidRange();
    error ElementNotFound();

    event ElementAdded(uint256 value, uint256 newLength);
    event ElementRemoved(uint256 index, uint256 value);
    event ArrayCleared();

    //1. 安全添加
    function safePush(uint256 _value) public returns (uint256) {
        if (data.length >= MAX_LENGTH) {
            revert ArrayFull();
        }

        data.push(_value);
        emit ElementAdded(_value, data.length);

        return data.length;
    }

    //2. 安全批量添加
    function safePushMany(uint256[] memory _values) public returns (uint256) {
        if (data.length + _values.length > MAX_LENGTH) {
            revert ArrayFull();
        }

        for (uint256 i = 0; i < _values.length; i++) {
            data.push(_values[i]);
        }

        emit ElementAdded(0, data.length);
        return data.length;
    }

    //3. 有序删除
    function removeOrdered(uint256 _index) public returns (uint256) {
        if (_index >= data.length) {
            revert InvalidIndex();
        }

        uint256 removedValue = data[_index];

        for (uint256 i = _index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();

        emit ElementRemoved(_index, removedValue);
        return removedValue;
    }

    //4. 快速删除
    function removeFast(uint256 _index) public returns (uint256) {
        if (_index >= data.length) {
            revert InvalidIndex();
        }

        uint256 removedValue = data[_index];
        uint256 lastValue = data[data.length - 1];

        data[_index] = lastValue;
        data.pop();

        emit ElementRemoved(_index, removedValue);
        return removedValue;
    }

    //5. 范围求和
    function sumRange(uint256 _start, uint256 _end) 
        public 
        view 
        returns (uint256) 
    {
        if (_start >= data.length || _end >= data.length || _start > _end) {
            revert InvalidRange();
        }

        uint256 sum = 0;
        for (uint256 i = _start; i <= _end; i++) {
            sum += data[i];
        }

        return sum;
    }

    //6. 分批求和
    function sumBatch(uint256 _batchSize) public view returns (uint256[] memory) {
        if (_batchSize == 0 || _batchSize > data.length) {
            revert InvalidRange();
        }

        uint256 batchCount = (data.length + _batchSize - 1) / _batchSize;
        uint256[] memory results = new uint256[](batchCount);

        for (uint256 i = 0; i < batchCount; i++) {
            uint256 start = i * _batchSize;
            uint256 end = start + _batchSize;
            
            if (end > data.length) {
                end = data.length;
            }

            uint256 sum = 0;
            for (uint256 j = start; j < end; j++) {
                sum += data[j];
            }
            results[i] = sum;
        }

        return results;
    }

    //7. 查找元素
    function find(uint256 _value) public view returns (int256) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == _value) {
                return int256(i);
            }
        }
        return -1;
    }

    //8. 查找所有元素
    function findAll(uint256 _value) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == _value) {
                count++;
            }
        }

        uint256[] memory indices = new uint256[](count);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == _value) {
                indices[currentIndex] = i;
                currentIndex++;
            }
        }

        return indices;
    }

    //9. 获取所有元素
    function getAll() public view returns (uint256[] memory) {
        return data;
    }

    //10. 获取数组长度
    function getLength() public view returns (uint256) {
        return data.length;
    }

    //11. 获取元素
    function getElement(uint256 _index) public view returns (uint256) {
        if (_index >= data.length) {
            revert InvalidIndex();
        }
        return data[_index];
    }

    //12. 清空数组
    function clear() public {
        delete data;
        emit ArrayCleared();
    }

    //13. 检查元素是否存在
    function contains(uint256 _value) public view returns (bool) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == _value) {
                return true;
            }
        }
        return false;
    }

    //14. 求和
    function sumAll() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        return sum;
    }

    //15. 求平均值
    function average() public view returns (uint256) {
        if (data.length == 0) {
            return 0;
        }
        return sumAll() / data.length;
    }

    //16. 求最大值
    function getMax() public view returns (uint256) {
        if (data.length == 0) {
            return 0;
        }

        uint256 maxVal = data[0];
        for (uint256 i = 1; i < data.length; i++) {
            if (data[i] > maxVal) {
                maxVal = data[i];
            }
        }
        return maxVal;
    }

    //17. 求最小值
    function getMin() public view returns (uint256) {
        if (data.length == 0) {
            return 0;
        }

        uint256 minVal = data[0];
        for (uint256 i = 1; i < data.length; i++) {
            if (data[i] < minVal) {
                minVal = data[i];
            }
        }
        return minVal;
    }
}
