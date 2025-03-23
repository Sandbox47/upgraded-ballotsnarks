import json
import os

class JSONUtils():
    def toJSON(obj, innerData):
        data = None
        if obj.name == None:
            data = innerData
        else:
            data = {
                obj.name: innerData
            }
        return data

    def arrayToJSON(data):
        if isinstance(data, list):
            return [JSONUtils.arrayToJSON(subdata) for subdata in data]
        elif hasattr(data, 'toJSON') and callable(getattr(data, 'toJSON')):
            try:
                return data.toJSON()
            except Exception as e:
                print(f"Error serializing {data}: {e}")
        else:
            # print(str(data))
            return str(data)

    def combine(dataArray):
        combinedData = {}
        for data in dataArray:
            if isinstance(data, dict):
                jsonData = data
            elif hasattr(data, 'toJSON') and callable(getattr(data, 'toJSON')):
                try:
                    # jsonData = json.loads(data.toJSON())
                    jsonData = data.toJSON()
                except Exception as e:
                    print(f"Error serializing {data}: {e}")
                    continue
            else:
                print(f"Skipping unsupported type: {type(data)}")
                continue
            combinedData = combinedData | jsonData
        return combinedData

    def exportToJSON(jsonData, filepath=None):
        if filepath == None: # Write to CMD
            print(json.dumps(jsonData, indent=4))
        else: # Write to file
            # Ensure the directory exists
            directory = os.path.dirname(filepath)
            if directory and not os.path.exists(directory):
                os.makedirs(directory)

            # Write to a JSON file
            with open(filepath, 'w') as f:
                json.dump(jsonData, f, indent=4)

    def combineAndExport(jsonDataArray, filePath=None):
        JSONUtils.exportToJSON(JSONUtils.combine(jsonDataArray), filePath)