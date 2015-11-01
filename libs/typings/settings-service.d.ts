declare module SettingsService {
    export interface ISettingsServiceSettings {
        host: string,
        fps: number,
        trackColor: string,
        trackWidth: number,
        trackOutlineColor: string,
        startFinishColor: string,
        sectorColor: string,
        showSectors: boolean,
        driverCircle: number,
        circleColor: string,
        driverHighlightWidth: number,
        driverHighlightCam: string,
        driverHighlightOfftrack: string,
        driverPosNum: string,
        highlightNum: string,
        playerHighlight: string,
        driverGroups: Array<ISettingsServiceDriverGroup>
    }

    export interface ISettingsServiceDriverGroup {
        ids: string,
        color: string
    }
}
